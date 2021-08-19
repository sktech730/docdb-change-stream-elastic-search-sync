import datetime
import json
import logging
import os

import boto3
from bson import json_util
from pymongo import ReadPreference, MongoClient
from pymongo.errors import OperationFailure
from amazon_docdb_client import get_db

TOKEN_DATA_DELETED_CODE = 136

sqs_url = os.environ["SQS_QUERY_URL"]
db_name = os.environ["DOCUMENTDB_NAME"]
sqs_client = None  # SQS client - used as target
collection_name = os.environ["COLLECTION_NAME"]
state_collection_name = "state"
endpoint_url = os.environ["SQS_ENDPOINT_URL"]
docs_per_iteration = os.environ["DOCUMENTS_PER_INVOCATION"]
sync_token_frequency = os.environ["SYNC_TOKEN_FREQUENCY"]
sqs = boto3.resource("sqs", endpoint_url=endpoint_url)
logger = logging.getLogger()
logger.setLevel(logging.INFO)
db = get_db()


def get_last_saved_token():
    last_processed_token = None
    try:
        state_collection = db.get_collection(state_collection_name)
        logger.info(f"state_collection : {state_collection}")
        state_doc = state_collection.find_one(
            {
                "currentState": True,
                "dbWatched": db_name,
                "collectionWatched": collection_name,
                "db_level": False,
            }
        )
        logger.info(f"state_doc:{state_doc}")
        if state_doc is not None:
            if "lastProcessed" in state_doc:
                last_processed_token = state_doc["lastProcessed"]
                logger.info(f"last_processed_token: {last_processed_token}")
        else:
            state_collection.insert_one(
                {
                    "dbWatched": db_name,
                    "collectionWatched": collection_name,
                    "currentState": True,
                    "db_level": False,
                }
            )

        return last_processed_token

    except Exception as exp:
        logger.error(f"error occured while getting last processed token: {str(exp)}")
        raise exp


def save_last_token(resume_token):
    try:
        state_collection = db.get_collection(state_collection_name)
        logger.info(f"resume_token is : {resume_token}")
        logger.info(f"collection_name: {collection_name}")
        state_collection.update_one(
            {
                "dbWatched": db_name,
                "collectionWatched": collection_name,
                "currentState": True,
                "db_level": False,
            },
            {"$set": {"lastProcessed": resume_token}},
        )
    except Exception as exp:
        logger.error(f"error ocuured while saving last processed token: {str(exp)}")
        raise exp


def insert_stream_activate_record():
    coll = db.get_collection(collection_name)
    test_record = coll.insert_one({"test": "test_record"})
    logger.info(f" test record insrted is {test_record}")
    return test_record


def delete_test_record():
    coll = db.get_collection(collection_name)
    deleted_record = coll.delete_one({"test": "test_record"})
    logger.info(f"deleted record is {deleted_record}")


def publish_sqs_event(pkey, message, order):
    """send event to FIFO SQS"""

    queue = sqs.Queue(sqs_url)
    try:
        logger.info("Publishing message to SQS.")
        response = queue.send_message(
            MessageBody=message, MessageDeduplicationId=pkey, MessageGroupId=order
        )
        logger.info(f"response from send message: {response}")

    except Exception as ex:
        logger.error("Exception in publishing message to SQS: {}".format(ex))
        raise ex


def lambda_handler(event, context):
    try:
        test_record = None
        last_saved_token = get_last_saved_token()
        collection_to_watch = db.get_collection(
            collection_name, read_preference=ReadPreference.PRIMARY
        )
        logger.info(f"collection_to_watch is {collection_to_watch}")
        events_processed = 0
        with collection_to_watch.watch(
                full_document="updateLookup", resume_after=last_saved_token
        ) as stream:
            i = 0
            if last_saved_token is None:
                test_record = insert_stream_activate_record()
                logger.info(f"test record to activate: {test_record}")
                delete_test_record()
            while stream.alive and i < int(docs_per_iteration):
                change_event = stream.try_next()
                logger.info(f"changed event is {change_event}")

                if last_saved_token is None:

                    if change_event["operationType"] == "delete":
                        save_last_token(stream.resume_token)
                        last_saved_token = change_event["_id"]["_data"]
                    continue

                if change_event is None:
                    break
                else:
                    logger.info(f"found changes in docdb: {change_event}")
                    i = i + 1
                    op_type = change_event["operationType"]
                    op_id = change_event["_id"]["_data"]
                    if op_type in ["insert", "update"]:
                        logger.info(f"operation type: {op_type}")
                        doc_body = change_event["fullDocument"]
                        if doc_body is not None:
                            doc_id = str(doc_body.pop("_id", None))
                        else:
                            doc_body = {}
                            document_key = change_event["documentKey"]
                            doc_id = document_key["_id"]
                        readable = datetime.datetime.fromtimestamp(
                            change_event["clusterTime"].time
                        ).isoformat()
                        doc_body.update(
                            {
                                "operation": op_type,
                                "timestamp": str(change_event["clusterTime"].time),
                                "timestampReadable": str(readable),
                            }
                        )
                        payload = {"_id": doc_id}
                        payload.update(doc_body)
                        if change_event.get("updateDescription", None) is not None:
                            doc_body_updated_fields = change_event["updateDescription"]
                            logger.info(
                                f"updated fields are: {doc_body_updated_fields}"
                            )
                            updated_fields_map = doc_body_updated_fields["updatedFields"]
                            updated_fields_map.update(
                                {
                                    "operation": op_type,
                                    "timestamp": str(change_event["clusterTime"].time),
                                    "timestampReadable": str(readable),
                                }
                            )
                            doc_body_updated_fields.update(updated_fields_map)
                            logger.info(
                                f"updated fields with extra fields: {doc_body_updated_fields}"
                            )
                            payload.update(doc_body_updated_fields)
                        logger.info(f"payload is : {payload}")
                        # Publish event to SQS
                        if "SQS_QUERY_URL" in os.environ:
                            order = str(change_event["ns"]["coll"])
                            logger.info(f"sqs order is : {order}")
                            logger.info(
                                f"publishing to sqs: event {str(op_id)}, message:{json_util.dumps(payload)}, order: {order}"
                            )
                            publish_sqs_event(
                                str(op_id), json_util.dumps(payload), order
                            )

                    if op_type == "delete":
                        logger.info(f"operation type: {op_type}")
                        doc_body = {}
                        doc_id = str(change_event["documentKey"]["_id"])
                        readable = datetime.datetime.fromtimestamp(
                            change_event["clusterTime"].time
                        ).isoformat()
                        doc_body.update(
                            {
                                "operation": op_type,
                                "timestamp": str(change_event["clusterTime"].time),
                                "timestampReadable": str(readable),
                            }
                        )
                        payload = {"_id": doc_id}
                        payload.update(doc_body)

                        if "SQS_QUERY_URL" in os.environ:
                            order = str(change_event["ns"]["coll"])
                            logger.info(f"in delete : sqs order is : {order}")
                            logger.info(
                                f"publishing to sqs: event {str(op_id)}, message:{json_util.dumps(payload)}, order: {order}"
                            )
                            publish_sqs_event(
                                str(op_id), json_util.dumps(payload), order
                            )

                    events_processed += 1

                    if events_processed >= int(sync_token_frequency):
                        # To reduce DocumentDB IO, only persist the stream state every N events
                        save_last_token(stream.resume_token)
                        logger.info(
                            "Synced token {} to state collection".format(
                                stream.resume_token
                            )
                        )

                    logger.info("Processed event ID {}".format(op_id))

    except OperationFailure as operation_failure:
        if operation_failure.code == TOKEN_DATA_DELETED_CODE:
            save_last_token(None)
        raise operation_failure
    except Exception as ex:
        logger.error("Exception in executing replication: {}".format(ex))
        raise ex
    else:
        if i > 0:
            save_last_token(stream.resume_token)
            logger.info(
                "Synced token {} to state collection".format(stream.resume_token)
            )
            return_doc = {
                "statusCode": 200,
                "description": "Success",
                "detail": json.dumps(str(i) + " documents processed successfully."),
            }
            logger.info(return_doc)
        else:
            if test_record is not None:
                return_doc = {
                    "statusCode": 202,
                    "description": "Success",
                    "detail": json.dumps("tet record applied. No records to process."),
                }
                logger.info(return_doc)
            else:
                return_doc = {
                    "statusCode": 201,
                    "description": "Success",
                    "detail": json.dumps("No records to process."),
                }
                logger.info(return_doc)