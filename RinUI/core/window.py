import ctypes
import platform
import sys
import weakref
from ctypes import wintypes

from PySide6.QtCore import QAbstractNativeEventFilter, QByteArray, QObject, QTimer, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickWindow

from RinUI.core.config import is_windows
from RinUI.core.errors import WindowError

_win32_available = sys.platform == "win32"
if _win32_available:
    import win32con
    from win32api import GetSystemMetrics, MonitorFromWindow, SendMessage
    from win32com.shell.shellcon import (
        ABM_GETSTATE,
        ABM_GETTASKBARPOS,
        ABS_AUTOHIDE,
    )
    from win32con import (
        MONITOR_DEFAULTTONEAREST,
        MONITOR_DEFAULTTOPRIMARY,
        SM_CXSIZEFRAME,
        SM_CYSIZEFRAME,
        SW_MAXIMIZE,
        WS_BORDER,
        WS_CAPTION,
        WS_THICKFRAME,
    )
    from win32gui import FindWindow, GetWindowPlacement, ReleaseCapture

    user32 = ctypes.windll.user32

# 定义 Windows 类型
ULONG_PTR = (
    ctypes.c_ulong if ctypes.sizeof(ctypes.c_void_p) == 4 else ctypes.c_ulonglong
)
LONG = ctypes.c_long


# 自定义结构体 MONITORINFO
class MONITORINFO(ctypes.Structure):
    _fields_ = [
        ("cbSize", wintypes.DWORD),
        ("rcMonitor", wintypes.RECT),
        ("rcWork", wintypes.RECT),
        ("dwFlags", wintypes.DWORD),
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


class PWINDOWPOS(ctypes.Structure):
    _fields_ = [
        ("hWnd", wintypes.HWND),
        ("hwndInsertAfter", wintypes.HWND),
        ("x", ctypes.c_int),
        ("y", ctypes.c_int),
        ("cx", ctypes.c_int),
        ("cy", ctypes.c_int),
        ("flags", wintypes.UINT),
    ]


class NCCALCSIZE_PARAMS(ctypes.Structure):
    _fields_ = [("rgrc", wintypes.RECT * 3), ("lppos", ctypes.POINTER(PWINDOWPOS))]


class APPBARDATA(ctypes.Structure):
    _fields_ = [
        ("cbSize", wintypes.UINT),
        ("hWnd", wintypes.HWND),
        ("uCallbackMessage", wintypes.UINT),
        ("uEdge", wintypes.UINT),
        ("rc", wintypes.RECT),
        ("lParam", wintypes.LPARAM),
    ]


class MARGINS(ctypes.Structure):
    _fields_ = [
        ("cxLeftWidth", ctypes.c_int),
        ("cxRightWidth", ctypes.c_int),
        ("cyTopHeight", ctypes.c_int),
        ("cyBottomHeight", ctypes.c_int),
    ]


# 定义必要的 Windows 常量
WM_NCCALCSIZE = 0x0083
WM_NCHITTEST = 0x0084
WM_SYSCOMMAND = 0x0112
WM_GETMINMAXINFO = 0x0024
WM_SIZE = 0x0005
WM_PAINT = 0x000F
WM_ERASEBKGND = 0x0014
WM_WINDOWPOSCHANGED = 0x0047
WM_DWMCOMPOSITIONCHANGED = 0x031E
WM_ACTIVATE = 0x0006
WM_NCACTIVATE = 0x0086
WM_ACTIVATEAPP = 0x001C
WM_SHOWWINDOW = 0x0018

SC_MINIMIZE = 0xF020
SC_MAXIMIZE = 0xF030
SC_RESTORE = 0xF120


def _get_window_int_property(window, name: str, default: int) -> int:
    """获取窗口整数属性"""
    val = getattr(window, name, None)
    if val is None:
        return default
    if callable(val):
        val = val()
    if val is None:
        return default
    try:
        return int(val)
    except (TypeError, ValueError):
        return default


class MINMAXINFO(ctypes.Structure):
    _fields_ = [
        ("ptReserved", wintypes.POINT),
        ("ptMaxSize", wintypes.POINT),
        ("ptMaxPosition", wintypes.POINT),
        ("ptMinTrackSize", wintypes.POINT),
        ("ptMaxTrackSize", wintypes.POINT),
    ]


def is_maximized(hwnd: int) -> bool:
    placement = GetWindowPlacement(hwnd)
    return placement[1] == SW_MAXIMIZE


def is_composition_enabled() -> bool:
    result = ctypes.c_int(0)
    ctypes.windll.dwmapi.DwmIsCompositionEnabled(ctypes.byref(result))
    return bool(result.value)


def find_window(hwnd: int):
    if not hwnd:
        return None

    windows = QGuiApplication.topLevelWindows()
    if not windows:
        return None

    for window in windows:
        if window and int(window.winId()) == hwnd:
            return window
    return None


def get_resize_border_thickness(hwnd: wintypes.HWND, horizontal=True) -> int:
    window = find_window(int(hwnd))
    if not window:
        return 0

    frame = SM_CXSIZEFRAME if horizontal else SM_CYSIZEFRAME
    result = GetSystemMetrics(frame) + GetSystemMetrics(92)

    if result > 0:
        return result

    thickness = 8 if is_composition_enabled() else 4
    return round(thickness * window.devicePixelRatio())


def is_exact_monitor_sized_window(window: QQuickWindow, hwnd: int) -> bool:
    if not window:
        return False

    monitor = user32.MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)
    if not monitor:
        return False

    monitor_info = MONITORINFO()
    monitor_info.cbSize = ctypes.sizeof(MONITORINFO)
    monitor_info.dwFlags = 0
    if not user32.GetMonitorInfoW(monitor, ctypes.byref(monitor_info)):
        return False

    rect = wintypes.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    geometry_matches_monitor = (
        rect.left == monitor_info.rcMonitor.left
        and rect.top == monitor_info.rcMonitor.top
        and rect.right == monitor_info.rcMonitor.right
        and rect.bottom == monitor_info.rcMonitor.bottom
    )
    if geometry_matches_monitor:
        return True

    screen = window.screen()
    ratio = screen.devicePixelRatio() if screen else window.devicePixelRatio()
    width = round(window.width() * ratio)
    height = round(window.height() * ratio)
    return (
        width == monitor_info.rcMonitor.right - monitor_info.rcMonitor.left
        and height == monitor_info.rcMonitor.bottom - monitor_info.rcMonitor.top
    )


class WinEventManager(QObject):
    def __init__(self):
        super().__init__()
        self.windows = []
        self.on_window_frame_changed = None
        self.pending_frame_sync_windows = []

    def set_windows(self, windows: list, on_window_frame_changed=None):
        self.windows = windows
        self.on_window_frame_changed = on_window_frame_changed

    def flush_pending_frame_sync_windows(self):
        pending_windows = self.pending_frame_sync_windows
        self.pending_frame_sync_windows = []
        for window in pending_windows:
            self.syncWindowFrame(window)

    @Slot(QObject, result=int)
    def getWindowId(self, window):
        """获取窗口的句柄"""
        # print(f"GetWindowId: {window.winId()}")
        return int(window.winId())

    @Slot(int)
    def drag_window_event(self, hwnd: int):
        """在Windows 用原生方法拖动"""
        if not is_windows() or type(hwnd) is not int or hwnd == 0:
            raise WindowError(
                f"Use Qt method to drag window on: {platform.system()}"
                if not is_windows()
                else f"Invalid window handle: {hwnd}"
            )

        ReleaseCapture()
        SendMessage(
            hwnd, win32con.WM_SYSCOMMAND, win32con.SC_MOVE | win32con.HTCAPTION, 0
        )

    @Slot(QObject)
    def syncWindowFrame(self, window):
        if not is_windows() or window is None:
            return

        try:
            hwnd = int(window.winId())
        except Exception:
            if window not in self.pending_frame_sync_windows:
                self.pending_frame_sync_windows.append(window)
            return

        if not self.windows:
            if window not in self.pending_frame_sync_windows:
                self.pending_frame_sync_windows.append(window)
            return

        style = user32.GetWindowLongPtrW(hwnd, -16)
        user32.SetWindowLongPtrW(hwnd, -16, style | WS_CAPTION | WS_THICKFRAME)
        if window.property("backdropEnabled") and is_composition_enabled():
            margins = MARGINS(-1, -1, -1, -1)
            ctypes.windll.dwmapi.DwmExtendFrameIntoClientArea(
                hwnd, ctypes.byref(margins)
            )
        user32.SendMessageW(hwnd, WM_ACTIVATEAPP, 1, 0)
        user32.SendMessageW(hwnd, WM_NCACTIVATE, 1, 0)
        user32.SendMessageW(hwnd, WM_ACTIVATE, 1, 0)
        user32.SetWindowPos(
            hwnd, 0, 0, 0, 0, 0, 0x0002 | 0x0001 | 0x0004 | 0x0010 | 0x0020
        )
        window.requestActivate()
        if self.on_window_frame_changed is not None:
            QTimer.singleShot(0, self.on_window_frame_changed)

    @Slot(QObject)
    def maximizeWindow(self, window):
        """在Windows上最大化或还原窗口"""
        if not is_windows() or window is None:
            raise WindowError(
                f"Use Qt method to drag window on: {platform.system()}"
                if not is_windows()
                else "Invalid window object"
            )

        try:
            hwnd = int(window.winId())
            if is_maximized(hwnd):
                window.showNormal()
            else:
                window.showMaximized()

        except Exception as err:
            raise WindowError(f"Error toggling window state: {err}") from err


class WinEventFilter(QAbstractNativeEventFilter):
    def __init__(self, windows: list, on_window_visible=None):
        super().__init__()
        self.windows = [weakref.ref(w) for w in windows]
        self.hwnds = {}  # hwnd(int) -> window 映射
        self.resize_border = 8

        for window_ref in self.windows:
            window = window_ref()
            if window is not None:
                window.visibleChanged.connect(
                    lambda visible, w=window: self._on_visible_changed(visible, w)
                )

    def initialize_windows(self):
        for window_ref in self.windows:
            window = window_ref()
            if window is not None:
                self._init_window_handle(window)

    def _on_visible_changed(self, visible: bool, window: QQuickWindow):
        if visible and window.winId() not in self.hwnds:
            self._init_window_handle(window)

    def _init_window_handle(self, window: QQuickWindow):
        hwnd = int(window.winId())
        self.hwnds[hwnd] = window
        self.sync_window_backdrop(window)

    def _find_window_by_hwnd(self, hwnd: int) -> QQuickWindow | None:
        return self.hwnds.get(hwnd)

    def sync_window_backdrop(self, window: QQuickWindow):
        self.set_window_styles(window)
        self.extend_frame_into_client_area(window)
        self.apply_fullscreen_opengl_border_workaround(window)

    def set_window_styles(self, window: QQuickWindow):
        hwnd = int(window.winId()) if window else None
        if hwnd is None:
            return

        style = user32.GetWindowLongPtrW(hwnd, -16)  # GWL_STYLE
        new_style = style | WS_CAPTION | WS_THICKFRAME
        if new_style == style:
            return

        user32.SetWindowLongPtrW(hwnd, -16, new_style)  # GWL_STYLE
        window.setProperty("_rinuiWindowStyleChanged", True)
        self.refresh_window_frame(window)

    def refresh_window_frame(self, window: QQuickWindow):
        hwnd = int(window.winId()) if window else None
        if hwnd is None:
            return

        user32.SetWindowPos(
            hwnd, 0, 0, 0, 0, 0, 0x0002 | 0x0001 | 0x0004 | 0x0010 | 0x0020
        )  # SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED

    def refresh_window_frame_if_needed(self, window: QQuickWindow):
        hwnd = int(window.winId()) if window else None
        if hwnd is None:
            return

        if not window.property("_rinuiWindowStyleChanged"):
            return

        window.setProperty("_rinuiWindowStyleChanged", False)
        self.refresh_window_frame(window)

    def extend_frame_into_client_area(self, window: QQuickWindow):
        if not window.property("backdropEnabled"):
            return

        hwnd = int(window.winId()) if window else None
        if hwnd is None or not is_composition_enabled():
            return

        margins = MARGINS(-1, -1, -1, -1)
        ctypes.windll.dwmapi.DwmExtendFrameIntoClientArea(hwnd, ctypes.byref(margins))

    def apply_fullscreen_opengl_border_workaround(self, window: QQuickWindow):
        if not window.property("enableFullscreenOpenGLBorderWorkaround"):
            return

        hwnd = int(window.winId()) if window else None
        if hwnd is None or not is_exact_monitor_sized_window(window, hwnd):
            return

        style = user32.GetWindowLongPtrW(hwnd, -16)
        if style & WS_BORDER:
            return

        user32.SetWindowLongPtrW(hwnd, -16, style | WS_BORDER)
        self.refresh_window_frame(window)

    def nativeEventFilter(self, event_type: QByteArray, message):
        if event_type not in (b"windows_generic_MSG", b"windows_dispatcher_MSG"):
            return False, 0

        try:
            message_addr = int(message)
        except Exception:
            buf = memoryview(message)
            message_addr = ctypes.addressof(ctypes.c_char.from_buffer(buf))

        # 直接使用内存地址访问 MSG 字段
        hwnd = ctypes.c_void_p.from_address(message_addr).value
        message_id = wintypes.UINT.from_address(
            message_addr + ctypes.sizeof(ctypes.c_void_p)
        ).value
        w_param = wintypes.WPARAM.from_address(
            message_addr + 2 * ctypes.sizeof(ctypes.c_void_p)
        ).value
        l_param = wintypes.LPARAM.from_address(
            message_addr + 3 * ctypes.sizeof(ctypes.c_void_p)
        ).value

        window = self._find_window_by_hwnd(hwnd)
        if window is None:
            return False, 0
        # 消息分发
        if message_id == WM_NCHITTEST:
            return self._handle_nchittest(window, l_param)
        if message_id == WM_NCCALCSIZE:
            return self._handle_nccalsize(window, w_param, l_param)
        if message_id == WM_GETMINMAXINFO:
            return self._handle_getminmaxinfo(window, hwnd, l_param)
        if message_id == WM_SYSCOMMAND:
            return False, 0  # 支持动画
        if message_id in (
            WM_SIZE,
            WM_WINDOWPOSCHANGED,
            WM_SHOWWINDOW,
            WM_ACTIVATE,
            WM_NCACTIVATE,
            WM_ACTIVATEAPP,
            WM_DWMCOMPOSITIONCHANGED,
        ):
            self.extend_frame_into_client_area(window)

        if message_id in (
            WM_SIZE,
            WM_WINDOWPOSCHANGED,
            WM_DWMCOMPOSITIONCHANGED,
        ):
            self.apply_fullscreen_opengl_border_workaround(window)

        return False, 0

    def _handle_nchittest(self, window: QQuickWindow, l_param):
        x = ctypes.c_short(l_param & 0xFFFF).value
        y = ctypes.c_short((l_param >> 16) & 0xFFFF).value

        hwnd = int(window.winId())
        rect = wintypes.RECT()
        user32.GetWindowRect(hwnd, ctypes.byref(rect))
        win_left, win_top, win_right, win_bottom = (
            rect.left,
            rect.top,
            rect.right,
            rect.bottom,
        )
        border = self.resize_border
        # 边框区域
        hit_result = self._hit_test_border(
            x, y, win_left, win_top, win_right, win_bottom, border
        )
        if hit_result is not None:
            return True, hit_result
        # 标题栏区域
        title_bar_height = window.property("titleBarHeight") or 32
        screen = window.screen()
        dp_ratio = screen.devicePixelRatio() if screen else 1.0
        title_bar_height_px = int(title_bar_height * dp_ratio)
        if win_top <= y < win_top + title_bar_height_px:
            return True, 1  # HTCAPTION

        return False, 0

    def _hit_test_border(self, x, y, win_left, win_top, win_right, win_bottom, border):
        """边框区域"""
        if win_left <= x < win_left + border:
            if win_top <= y < win_top + border:
                return 13  # HTTOPLEFT
            if win_bottom - border <= y < win_bottom:
                return 16  # HTBOTTOMLEFT
            return 10  # HTLEFT
        if win_right - border <= x < win_right:
            if win_top <= y < win_top + border:
                return 14  # HTTOPRIGHT
            if win_bottom - border <= y < win_bottom:
                return 17  # HTBOTTOMRIGHT
            return 11  # HTRIGHT
        if win_top <= y < win_top + border:
            return 12  # HTTOP
        if win_bottom - border <= y < win_bottom:
            return 15  # HTBOTTOM
        return None

    def _handle_nccalsize(self, window: QQuickWindow, w_param, l_param):
        if not w_param:
            return False, 0

        # 移除标题栏
        client_rect = ctypes.cast(
            l_param, ctypes.POINTER(NCCALCSIZE_PARAMS)
        ).contents.rgrc[0]

        hwnd = int(window.winId())
        if is_maximized(hwnd):
            self._adjust_maximized_rect(hwnd, client_rect)
        return True, 0

    def _adjust_maximized_rect(self, hwnd: int, client_rect):
        """最大化时客户区矩形"""
        ty = get_resize_border_thickness(hwnd, False)
        client_rect.top += ty
        client_rect.bottom -= ty
        tx = get_resize_border_thickness(hwnd, True)
        client_rect.left += tx
        client_rect.right -= tx
        # 检查任务栏
        taskbar_edge = self._get_taskbar_edge(hwnd)
        if taskbar_edge == 1:  # top
            client_rect.top += 1
        elif taskbar_edge == 3:  # bottom
            client_rect.bottom -= 1
        elif taskbar_edge == 0:  # left
            client_rect.left += 1
        elif taskbar_edge == 2:  # right
            client_rect.right -= 1
        else:
            client_rect.bottom -= 1

    def _get_taskbar_edge(self, hwnd: int) -> int:
        """
        获取任务栏位置
        返回: 0=left, 1=top, 2=right, 3=bottom, -1=unknown
        """
        abd = APPBARDATA()
        ctypes.memset(ctypes.byref(abd), 0, ctypes.sizeof(abd))
        abd.cbSize = ctypes.sizeof(APPBARDATA)
        taskbar_state = ctypes.windll.shell32.SHAppBarMessage(
            ABM_GETSTATE, ctypes.byref(abd)
        )

        if not (taskbar_state & ABS_AUTOHIDE):
            return -1
        taskbar_hwnd = FindWindow("Shell_TrayWnd", None)
        if not taskbar_hwnd:
            return -1
        window_monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)
        taskbar_monitor = MonitorFromWindow(taskbar_hwnd, MONITOR_DEFAULTTOPRIMARY)
        if (
            not window_monitor
            or not taskbar_monitor
            or taskbar_monitor != window_monitor
        ):
            return -1
        abd2 = APPBARDATA()
        ctypes.memset(ctypes.byref(abd2), 0, ctypes.sizeof(abd2))
        abd2.cbSize = ctypes.sizeof(APPBARDATA)
        abd2.hWnd = taskbar_hwnd
        ctypes.windll.shell32.SHAppBarMessage(ABM_GETTASKBARPOS, ctypes.byref(abd2))
        return abd2.uEdge

    def _handle_getminmaxinfo(self, window: QQuickWindow, hwnd: int, l_param):
        monitor = user32.MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)

        monitor_info = MONITORINFO()
        monitor_info.cbSize = ctypes.sizeof(MONITORINFO)
        monitor_info.dwFlags = 0
        user32.GetMonitorInfoW(monitor, ctypes.byref(monitor_info))

        minmax_info = MINMAXINFO.from_address(l_param)

        # 最大化位置和大小
        minmax_info.ptMaxPosition.x = (
            monitor_info.rcWork.left - monitor_info.rcMonitor.left
        )
        minmax_info.ptMaxPosition.y = (
            monitor_info.rcWork.top - monitor_info.rcMonitor.top
        )
        minmax_info.ptMaxSize.x = (
            monitor_info.rcWork.right - monitor_info.rcMonitor.left
        )
        minmax_info.ptMaxSize.y = (
            monitor_info.rcWork.bottom - monitor_info.rcMonitor.top
        )

        screen = window.screen()
        dp_ratio = screen.devicePixelRatio() if screen else 1.0

        minmax_info.ptMinTrackSize.x = int(
            _get_window_int_property(window, "minimumWidth", 0) * dp_ratio
        )
        minmax_info.ptMinTrackSize.y = int(
            _get_window_int_property(window, "minimumHeight", 0) * dp_ratio
        )
        minmax_info.ptMaxTrackSize.x = int(
            _get_window_int_property(
                window,
                "maximumWidth",
                monitor_info.rcWork.right - monitor_info.rcWork.left,
            )
            * dp_ratio
        )
        minmax_info.ptMaxTrackSize.y = int(
            _get_window_int_property(
                window,
                "maximumHeight",
                monitor_info.rcWork.bottom - monitor_info.rcWork.top,
            )
            * dp_ratio
        )

        return True, 0
