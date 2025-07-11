import platform
from typing import Optional

from PySide6.QtCore import QAbstractNativeEventFilter, QByteArray, QObject, Slot
import ctypes
from ctypes import wintypes

import win32con
from PySide6.QtQuick import QQuickWindow
from win32gui import ReleaseCapture, GetWindowPlacement, ShowWindow
from win32con import SW_MAXIMIZE, SW_RESTORE
from win32api import SendMessage

from RinUI.core.config import is_windows

# 定义 Windows 类型
ULONG_PTR = ctypes.c_ulong if ctypes.sizeof(ctypes.c_void_p) == 4 else ctypes.c_ulonglong
LONG = ctypes.c_long


# 自定义结构体 MONITORINFO
class MONITORINFO(ctypes.Structure):
    _fields_ = [
        ('cbSize', wintypes.DWORD),
        ('rcMonitor', wintypes.RECT),
        ('rcWork', wintypes.RECT),
        ('dwFlags', wintypes.DWORD)
    ]


class MSG(ctypes.Structure):
    _fields_ = [
        ("hwnd", ctypes.c_void_p),
        ("message", wintypes.UINT),
        ("wParam", wintypes.WPARAM),
        ("lParam", wintypes.LPARAM),
        ("time", wintypes.DWORD),
        ("pt", wintypes.POINT),
    ]


user32 = ctypes.windll.user32

# 定义必要的 Windows 常量
WM_NCCALCSIZE = 0x0083
WM_NCHITTEST = 0x0084
WM_SYSCOMMAND = 0x0112
WM_GETMINMAXINFO = 0x0024

WS_CAPTION = 0x00C00000
WS_THICKFRAME = 0x00040000

SC_MINIMIZE = 0xF020
SC_MAXIMIZE = 0xF030
SC_RESTORE = 0xF120


class MINMAXINFO(ctypes.Structure):
    _fields_ = [
        ("ptReserved", wintypes.POINT),
        ("ptMaxSize", wintypes.POINT),
        ("ptMaxPosition", wintypes.POINT),
        ("ptMinTrackSize", wintypes.POINT),
        ("ptMaxTrackSize", wintypes.POINT),
    ]


class WinEventManager(QObject):
    @Slot(QObject, result=int)
    def getWindowId(self, window):
        """获取窗口的句柄"""
        print(f"GetWindowId: {window.winId()}")
        return int(window.winId())

    @Slot(int)
    def dragWindowEvent(self, hwnd: int):
        """ 在Windows 用原生方法拖动"""
        if not is_windows() or type(hwnd) is not int or hwnd == 0:
            print(
                f"Use Qt method to drag window on: {platform.system()}"
                if not is_windows() else f"Invalid window handle: {hwnd}"
            )
            return

        ReleaseCapture()
        SendMessage(
            hwnd,
            win32con.WM_SYSCOMMAND,
            win32con.SC_MOVE | win32con.HTCAPTION, 0
        )

    @Slot(int)
    def maximizeWindow(self, hwnd):
        """在Windows上最大化或还原窗口"""
        if not is_windows() or type(hwnd) is not int or hwnd == 0:
            print(
                f"Use Qt method to drag window on: {platform.system()}"
                if not is_windows() else f"Invalid window handle: {hwnd}"
            )
            return

        try:
            placement = GetWindowPlacement(hwnd)
            current_state = placement[1]

            if current_state == SW_MAXIMIZE:
                ShowWindow(hwnd, SW_RESTORE)
            else:
                ShowWindow(hwnd, SW_MAXIMIZE)

        except Exception as e:
            print(f"Error toggling window state: {e}")


class WinEventFilter(QAbstractNativeEventFilter):
    def __init__(self, window: QQuickWindow):
        super().__init__()
        self.window = window
        self.hwnd: Optional[int] = None
        self.resize_border = 8

        # ✅ 动态监听 visible 属性
        if not self.window.isVisible():
            self.window.visibleChanged.connect(self._on_visible_changed)
        else:
            self._init_window_handle()

    def _on_visible_changed(self, visible: bool):
        if visible and self.hwnd is None:
            self._init_window_handle()

    def _init_window_handle(self):
        self.hwnd = int(self.window.winId())
        self.set_window_styles()
        print(f"🏷️ Window handle set: hwnd={self.hwnd}")

    def set_window_styles(self):
        """设置必要的窗口样式以启用原生窗口行为"""
        style = user32.GetWindowLongPtrW(self.hwnd, -16)  # GWL_STYLE

        style |= WS_CAPTION | WS_THICKFRAME
        user32.SetWindowLongPtrW(self.hwnd, -16, style)  # GWL_STYLE

        # 重绘
        user32.SetWindowPos(self.hwnd, 0, 0, 0, 0, 0,
                            0x0002 | 0x0001 | 0x0040)  # SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED

    def nativeEventFilter(self, eventType: QByteArray, message):
        if eventType != b"windows_generic_MSG":
            return False, 0

        try:
            message_addr = int(message)
        except:
            buf = memoryview(message)
            message_addr = ctypes.addressof(ctypes.c_char.from_buffer(buf))

        # 直接使用内存地址访问 MSG 字段
        hwnd = ctypes.c_void_p.from_address(message_addr).value
        message_id = wintypes.UINT.from_address(message_addr + ctypes.sizeof(ctypes.c_void_p)).value
        wParam = wintypes.WPARAM.from_address(message_addr + 2 * ctypes.sizeof(ctypes.c_void_p)).value
        lParam = wintypes.LPARAM.from_address(message_addr + 3 * ctypes.sizeof(ctypes.c_void_p)).value

        if message_id == WM_NCHITTEST:
            x = ctypes.c_short(lParam & 0xFFFF).value
            y = ctypes.c_short((lParam >> 16) & 0xFFFF).value

            rect = wintypes.RECT()
            user32.GetWindowRect(self.hwnd, ctypes.byref(rect))
            left, top, right, bottom = rect.left, rect.top, rect.right, rect.bottom
            border = self.resize_border

            if left <= x < left + border:
                if top <= y < top + border:
                    return True, 13  # HTTOPLEFT
                elif bottom - border <= y < bottom:
                    return True, 16  # HTBOTTOMLEFT
                else:
                    return True, 10  # HTLEFT
            elif right - border <= x < right:
                if top <= y < top + border:
                    return True, 14  # HTTOPRIGHT
                elif bottom - border <= y < bottom:
                    return True, 17  # HTBOTTOMRIGHT
                else:
                    return True, 11  # HTRIGHT
            elif top <= y < top + border:
                return True, 12  # HTTOP
            elif bottom - border <= y < bottom:
                return True, 15  # HTBOTTOM

            # 其他区域不处理
            return False, 0

        # 移除标题栏
        elif message_id == WM_NCCALCSIZE and wParam:
            return True, 0

        # 支持动画
        elif message_id == WM_SYSCOMMAND:
            return False, 0

        # 处理 WM_GETMINMAXINFO 消息以支持 Snap 功能
        elif message_id == WM_GETMINMAXINFO:
            # 获取屏幕工作区大小
            monitor = user32.MonitorFromWindow(self.hwnd, 2)  # MONITOR_DEFAULTTONEAREST

            # 使用自定义的 MONITORINFO 结构
            monitor_info = MONITORINFO()
            monitor_info.cbSize = ctypes.sizeof(MONITORINFO)
            monitor_info.dwFlags = 0
            user32.GetMonitorInfoW(monitor, ctypes.byref(monitor_info))

            # 获取 MINMAXINFO 结构
            minmax_info = MINMAXINFO.from_address(lParam)

            # 设置最大化位置和大小
            minmax_info.ptMaxPosition.x = monitor_info.rcWork.left - monitor_info.rcMonitor.left
            minmax_info.ptMaxPosition.y = monitor_info.rcWork.top - monitor_info.rcMonitor.top
            minmax_info.ptMaxSize.x = monitor_info.rcWork.right - monitor_info.rcWork.left
            minmax_info.ptMaxSize.y = monitor_info.rcWork.bottom - monitor_info.rcWork.top

            # 设置最小跟踪大小
            minmax_info.ptMinTrackSize.x = 200  # 最小宽度
            minmax_info.ptMinTrackSize.y = 150  # 最小高度

            return True, 0

        return False, 0
