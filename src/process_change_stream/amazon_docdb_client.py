import json
import logging
import os
import boto3
from pymongo import MongoClient


_db_client = None

_logger = logging.getLogger()
_log_level = logging.getLevelName(logging.INFO)
_logger.setLevel(_log_level)


def get_collection(collection_name):
    db = get_db()
    return db[collection_name]


def get_db():
    """Return an authenticated connection to DocumentDB"""
    # Use a global variable so Lambda can reuse the
    # persisted client on future invocations
    global _db_client
    if _db_client is None:
        _logger.debug('Creating new DocumentDB client.')

        try:
            (username, password, cluster_uri) = get_credentials()
            _db_client = MongoClient(cluster_uri, ssl=True,retryWrites=False,
                                     ssl_ca_certs='rds-combined-ca-bundle.pem')

            # force the client to connect
            _db_client.admin.command('ismaster')
            _db_client["admin"].authenticate(name=username, password=password)

            _logger.debug('Successfully created new DocumentDB client.')
        except Exception as ex:
            _logger.error(
                'Failed to create new DocumentDB client: {}'.format(ex))
            raise

    db_name = os.environ['DOCUMENTDB_NAME']
    return _db_client[db_name]


def get_credentials():
    """Retrieve credentials from the Secrets Manager service."""
    boto_session = boto3.session.Session()

    try:
        secret_name = os.environ['DOCUMENTDB_SECRET']

        _logger.debug(
            'Retrieving secret {} from Secrets Manger.'.format(secret_name))

        secrets_client = boto_session.client(
            service_name='secretsmanager',
            region_name=boto_session.region_name)
        secret_value = secrets_client.get_secret_value(SecretId=secret_name)

        secret = secret_value['SecretString']
        secret_json = json.loads(secret)
        username = secret_json['username']
        password = secret_json['password']
        cluster_uri = secret_json['uri']

        _logger.debug(
            'Secret {} retrieved from Secrets Manger.'.format(secret_name))

        return username, password, cluster_uri

    except Exception:
        _logger.error('Failed to retrieve secret {}'.format(secret_name))
        raise