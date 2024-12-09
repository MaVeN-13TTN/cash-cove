import logging

class LoggerUtils:
    @staticmethod
    def info(message: str):
        logging.info(message)

    @staticmethod
    def error(message: str):
        logging.error(message)

    @staticmethod
    def debug(message: str):
        logging.debug(message)
