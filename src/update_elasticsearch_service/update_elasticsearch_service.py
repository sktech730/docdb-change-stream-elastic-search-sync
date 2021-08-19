import json
import logging
import os
import elasticsearch
import elasticsearch.exceptions
from elasticsearch_client import get_es_client

logger = logging.getLogger()
log_level = logging.getLevelName(logging.INFO)
logger.setLevel(log_level)

es_client = get_es_client()

def lambda_handler(event, context):
    logger.info(f"event details:{event}")
    records = event["Records"]
    for item in records:
        body = json.loads(item["body"])
        if body["operation"]:
            es_index = item["attributes"]["MessageGroupId"]
            if body["operation"] == "insert":
                uuid = body["_id"]
                body.pop("_id", None)
                response = es_client.index(index=es_index, id=uuid, body=body)
                logger.info(f"Insert response:{response}")
            if body["operation"] == "update":
                uuid = body["_id"]
                updated_fields = body["updatedFields"]
                try:
                    response = es_client.update(
                        index=es_index, id=uuid, body={"doc": updated_fields}
                    )
                    logger.info(f"update response: {response}")
                except elasticsearch.NotFoundError as NotFoundError:
                    logger.error(f"failed to update due to error : {NotFoundError}")

            if body["operation"] == "delete":
                uuid = body["_id"]
                try:
                    response = es_client.delete(index=es_index, id=uuid)
                    logger.info(f"delete response: {response}")
                except elasticsearch.NotFoundError as NotFoundError:
                    logger.error(f"failed to update due to error : {NotFoundError}")
