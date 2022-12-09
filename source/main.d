import core.runtime;
import core.sys.windows.windows;
import std.string;
import std.conv;
import std.utf;
import std.datetime : Clock;
import std.stdio;
import std.file;
import messages;


extern (Windows)
LRESULT WinMain( HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow )
{
    LRESULT result;

    try
    {
        Runtime.initialize();
        result = my_win_main( hInstance, hPrevInstance, lpCmdLine, iCmdShow );
        Runtime.terminate();
    }
    catch (Throwable o)
    {
        MessageBox( NULL, o.toString().toUTF16z, "Error", MB_OK | MB_ICONEXCLAMATION );
        result = 0;
    }

    return result;
}


auto my_win_main( HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow )
{
    auto className = toUTF16z( "My First M'ofocking Window" );
    WNDCLASS wndClass;

    //
    messages.messages_map_init();

    //
    auto f = "msg.log";
    if ( f.exists )
        f.remove();

    // Window
    wndClass.style = CS_HREDRAW | CS_VREDRAW;
    wndClass.lpfnWndProc   = &WndProc;
    wndClass.cbClsExtra    = 0;
    wndClass.cbWndExtra    = 0;
    wndClass.hInstance     = hInstance;
    wndClass.hIcon         = LoadIcon( null, IDI_EXCLAMATION );
    wndClass.hCursor       = LoadCursor( null, IDC_CROSS );
    wndClass.hbrBackground = GetStockObject( DKGRAY_BRUSH );
    wndClass.lpszMenuName  = null;
    wndClass.lpszClassName = className;


    try { info( "RegisterClass()" ); } catch ( Throwable e ) {}

    // Register
    if ( !RegisterClass( &wndClass ) ) 
        throw new Exception( "Unable to register class" );

    try { info( "CreateWindow()" ); } catch ( Throwable e ) {}

    // Create
    HWND hWnd;
    hWnd = CreateWindow(
        className,                        //Window class used.
        "The program".toUTF16z,           //Window caption.
        WS_OVERLAPPEDWINDOW,              //Window style.
        CW_USEDEFAULT,                    //Initial x position.
        CW_USEDEFAULT,                    //Initial y position.
        CW_USEDEFAULT,                    //Initial x size.
        CW_USEDEFAULT,                    //Initial y size.
        null,                             //Parent window handle.
        null,                             //Window menu handle.
        hInstance,                        //Program instance handle.
        null                              //Creation parameters.
    );                           

    try { info( "ShowWindow()" ); } catch ( Throwable e ) {}

    // Show
    ShowWindow( hWnd, SW_SHOWMAXIMIZED );

    try { info( "UpdateWindow()" ); } catch ( Throwable e ) {}
    UpdateWindow( hWnd ); 

    try { info( "GetMessage()" ); } catch ( Throwable e ) {}

    // Main loop
    MSG msg;
    while ( GetMessage( &msg, null, 0, 0 ) ) 
    {
        TranslateMessage( &msg );
        DispatchMessage( &msg );
    }

    return msg.wParam; 
}


extern( Windows ) nothrow 
LRESULT WndProc( HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam ) 
{
    HDC hdc;
    PAINTSTRUCT ps; 
    RECT rect;

    try {
        //info( "  ", messages_map.get( message, "" ), ": ", message.to!string );
        info( "  ", messages_map.get( message, ":" ~ message.to!string ) );
    }
    catch ( Throwable e )
    {
        //
    }

    switch( message ) 
    {
        case WM_CREATE: return 0;
        case WM_PAINT:
            InvalidateRect( hwnd, null, true );
            hdc = BeginPaint( hwnd, &ps );
            GetClientRect( hwnd, &rect ); 
            DrawText( hdc, "Hello!", -1, &rect, DT_SINGLELINE | DT_CENTER | DT_VCENTER );
            EndPaint( hwnd, &ps ) ;
            return 0;
        case WM_DESTROY: PostQuitMessage( 0 ); return 0;
        case WM_LBUTTONDOWN:
            InvalidateRect( hwnd, null, true );
            hdc = BeginPaint( hwnd, &ps );
            GetClientRect( hwnd, &rect );
            DrawText( hdc, "WM_LBUTTONDOWN", -1, &rect, DT_SINGLELINE | DT_CENTER | DT_VCENTER );
            EndPaint( hwnd, &ps );
            return 0;      
        case WM_LBUTTONUP: return 0;
        default:
    }

    return DefWindowProc( hwnd, message, wParam, lParam );
}


//
// Logging
//
enum LogLevel { INFO, WARN, ERROR }

// Nested template to allow aliasing LogLevels.
// This makes it easily possible to create wrapper aliases without creating new
// wrapper functions which would alter the FILE, LINE and FUNCTION constants.
template log(LogLevel level)
{
    void log(Args...)(
        Args args,
        string fn = __FUNCTION__, // fully qualified function name of the caller
        string file = __FILE__,   // filename of the caller as specified in the compilation
        size_t line = __LINE__    // line number of the caller
    )
    {
        // Instead of using the default string conversion of Clock.currTime()
        // we could use Clock.currTime().toISOExtString() for a machine parsable
        // format or have a static constructor initializing a global MonoTime
        // variable at program startup and subtract from it here to have a time
        // offset from the start of the program being logged which is guaranteed
        // to only increase. (as opposed to the clock, which could change with
        // leap days, leap seconds or system clock manipulation)

        auto f = File( "msg.log", "a+t");
        f.
            writeln(
                //Clock.currTime(), // dump date & time with default format
                //" [", level, "] ", // automatically converts enum member name to string
                  //file,
                 //'(', line, "): ",
                  //fn, ": ",
                  args // actual log arguments, all dumped using writeln
            );
        f.close();
    }
}

// convenience aliases, uses nested templates to allow easily doing this
alias info = log!(LogLevel.INFO);
alias warn = log!(LogLevel.WARN);
alias error = log!(LogLevel.ERROR);

    //info("hello ", "world");
    //warn("we are", " number ", 1);
    //log!(LogLevel.INFO)("manual call");
    //error(true);
