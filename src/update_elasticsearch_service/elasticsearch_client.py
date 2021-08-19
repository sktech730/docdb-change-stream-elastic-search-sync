import logging
import os

from elasticsearch import Elasticsearch, helpers

_logger = logging.getLogger()
_log_level = logging.getLevelName(os.getenv("LOG_LEVEL", "ERROR"))
_logger.setLevel(_log_level)

_es_client = None
_es_uri = os.environ["ELASTICSEARCH_URI"]


def get_es_client():
    """Return an Elasticsearch client.
    Required environment variables for where data should be streamed:
    ELASTICSEARCH_URI: The URI of the Elasticsearch domain.
    """
    global _es_client
    if _es_client is None:
        _logger.debug("Creating Elasticsearch client Amazon root CA")

        try:
            _es_client = Elasticsearch(
                _es_uri,
                timeout=60,
                use_ssl=True,
                ca_certs="AmazonRootCA1.pem",
            )
        except Exception as ex:
            _logger.error("Failed to create new Elasticsearch client: {}".format(ex))
            raise
    return _es_client
