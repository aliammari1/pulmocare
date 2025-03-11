#include "win32_window.h"

Win32Window::Win32Window()
{
    // Window class name
    window_class_ = L"FLUTTER_RUNNER_WIN32_WINDOW";

    // Register window class
    WNDCLASS window_class = {0};
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = window_class_;
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.lpfnWndProc = DefWindowProc;
    RegisterClass(&window_class);
}

Win32Window::~Win32Window()
{
    UnregisterClass(window_class_, nullptr);
}
