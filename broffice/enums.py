from enum import Enum


class UserKind(Enum):
    ADMIN = 1
    WORKER = 2
    CLIENT = 3

class TaskKind(Enum):
    CLEANING = 4
    SNACKBAR = 5 
    OFFICESUPPLY = 6
