from enum import Enum


class UserKind(Enum):
    ADMIN = 1
    STAFF = 2
    CLIENT = 3

class TaskKind(Enum):
    CLEANING = 4
    SNACK = 5 
    OFFICE_SUPPLIES = 6
