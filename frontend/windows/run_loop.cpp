#include "run_loop.h"

#include <Windows.h>

void RunLoop::Run()
{
    MSG msg;
    while (GetMessage(&msg, nullptr, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
}

void RunLoop::Stop()
{
    PostQuitMessage(0);
}
