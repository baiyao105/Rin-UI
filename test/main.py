


import sys

from PySide6.QtCore import Qt, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication
from RinUI import RinUIWindow

if __name__ == '__main__':
    app = QApplication(sys.argv)

    window = RinUIWindow("popup-pos.qml")
    # window.set
    # window2 = RinUIWindow("test2.qml")
    # window3 = RinUIWindow("test3.qml")
    # print(window.engine)
    # print(window2.engine)
    # print(window3.engine)

    app.exec()
