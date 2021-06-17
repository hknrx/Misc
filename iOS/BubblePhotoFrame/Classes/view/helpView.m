#import "helpView.h"

static NSString* const html = @
"<html><body bgcolor=\"black\"><div style=\"font-family:Arial;color:white;-webkit-user-select:none\">"
#ifndef LITE_VERSION
"<center>Welcome to Photo Bubble!</center><br/>"
"<br/>"
"On the main menu, simply tap an environment bubble icon to enter the corresponding environment:<ul>"
"<li><img width=\"32\" height=\"32\" src=\"MenuLove.png\" align=\"absmiddle\"/>Love Frame;</li>"
"<li><img width=\"32\" height=\"32\" src=\"MenuMaze.png\" align=\"absmiddle\"/>Maze;</li>"
"<li><img width=\"32\" height=\"32\" src=\"MenuSpace.png\" align=\"absmiddle\"/>Outer Space;</li>"
"<li><img width=\"32\" height=\"32\" src=\"MenuPinball.png\" align=\"absmiddle\"/>Pinball;</li>"
"<li><img width=\"32\" height=\"32\" src=\"MenuRocks.png\" align=\"absmiddle\"/>Rocks;</li>"
"<li><img width=\"32\" height=\"32\" src=\"MenuTorture.png\" align=\"absmiddle\"/>Torture Room;</li>"
"<li><img width=\"32\" height=\"32\" src=\"MenuWashing.png\" align=\"absmiddle\"/>Washing Machine.</li></ul>"
"<br/>"
"Once in an environment, tap a photo bubble to modify it. The modification depends on the tool currently selected (the icon shown in blue):<ul>"
"<li><img width=\"32\" height=\"32\" src=\"MenuCamera.png\" align=\"absmiddle\"/>Take a new photo using the camera (iPhone only);</li>"
"<li><img width=\"32\" height=\"32\" src=\"MenuPhotoLibrary.png\" align=\"absmiddle\"/>Choose an existing picture from your photo library;</li>"
"<li><img width=\"32\" height=\"32\" src=\"MenuColorFilter.png\" align=\"absmiddle\"/>Apply a color filter.</li></ul>"
"Note that you can freely modify a picture during the selection process to only retain part of the image (e.g. a friend's face!). And don't worry: pictures taken from the photo library are copied to the application folder, original pictures aren't modified!<br/>"
"<br/>"
"Bubbles are subject to gravity, so moving your device will impact their behavior. In some environments, you can also make use of miscellaneous mechanisms, e.g. control the pinball's flippers or make the washing machine rotate faster!<br/>"
"<br/>"
"In order to display screenshots on your Facebook account, you first need to login to Facebook: just tap the connection button displayed in the top-right corner of the main menu. Once logged-in, a new button &quot;SHOT!&quot; will appear in each environment, allowing you to take an instant capture of the screen and upload it to your Facebook account!<br/>"
"<br/>"
"<img width=\"32\" height=\"32\" src=\"MenuMain.png\" align=\"right\"/>To go back to the main menu, just tap the home icon.<br/>"
"<br/>"
"Have fun with Photo Bubble!"
#else
"<center>Welcome to Photo Bubble Lite!</center><br/>"
"<br/>"
"<img width=\"32\" height=\"32\" src=\"MenuTorture.png\" align=\"right\"/>On the main menu, just tap the skull bubble icon to enter the torture room,<br/>"
"<img width=\"32\" height=\"32\" src=\"MenuRocks.png\" align=\"left\"/>or the rock bubble icon to select the rock environment.<br/>"
"<br/>"
"The full version of Photo Bubble also lets you enjoy the following environments:<ul>"
"<li><img width=\"32\" height=\"32\" src=\"MenuLove.png\" align=\"absmiddle\"/>Love Frame;</li>"
"<li><img width=\"32\" height=\"32\" src=\"MenuMaze.png\" align=\"absmiddle\"/>Maze;</li>"
"<li><img width=\"32\" height=\"32\" src=\"MenuSpace.png\" align=\"absmiddle\"/>Outer Space;</li>"
"<li><img width=\"32\" height=\"32\" src=\"MenuPinball.png\" align=\"absmiddle\"/>Pinball;</li>"
"<li><img width=\"32\" height=\"32\" src=\"MenuWashing.png\" align=\"absmiddle\"/>Washing Machine.</li></ul>"
"<br/>"
"Once in the torture room or the rock environment, tap a photo bubble to modify it. The modification depends on the tool currently selected (the icon shown in blue):<ul>"
"<li><img width=\"32\" height=\"32\" src=\"MenuCamera.png\" align=\"absmiddle\"/>Take a new photo using the camera (iPhone only);</li>"
"<li><img width=\"32\" height=\"32\" src=\"MenuPhotoLibrary.png\" align=\"absmiddle\"/>Choose an existing picture from your photo library;</li>"
"<li><img width=\"32\" height=\"32\" src=\"MenuColorFilter.png\" align=\"absmiddle\"/>Apply a color filter.</li></ul>"
"Note that you can freely modify a picture during the selection process to only retain part of the image (e.g. a friend's face!). And don't worry: pictures taken from the photo library are copied to the application folder, original pictures aren't modified!<br/>"
"<br/>"
"Bubbles are subject to gravity, so moving your device will impact their behavior!<br/>"
"<br/>"
"In order to display screenshots on your Facebook account, you first need to login to Facebook: just tap the connection button displayed in the top-right corner of the main menu. Once logged-in, a new button &quot;SHOT!&quot; will appear in each environment, allowing you to take an instant capture of the screen and upload it to your Facebook account!<br/>"
"<br/>"
"<img width=\"32\" height=\"32\" src=\"MenuMain.png\" align=\"right\"/>To go back to the main menu, just tap the home icon.<br/>"
"<br/>"
"Have fun with Photo Bubble Lite!"
#endif
"</div></body></html>";

@implementation HelpView

- (id)initWithFrame:(CGRect)frame withController:(UIViewController*)controller
{
	if(self = [super initWithFrame:frame])
	{
		UIToolbar* toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, 44.0f)];
		UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MenuMainBar.png"] style:UIBarButtonItemStyleBordered target:controller action:@selector(helpClose:)];
		[toolBar setBarStyle:UIBarStyleBlack];
		[toolBar setItems:[NSArray arrayWithObjects:space, button, nil] animated:NO];
		[self addSubview:toolBar];
		[button release];
		[space release];
		[toolBar release];

		webView = [[UIWebView alloc] initWithFrame:CGRectMake(0.0f, 44.0f, frame.size.width, frame.size.height - 44.0f)];
		webView.backgroundColor = [UIColor blackColor];
		webView.hidden = YES;
		webView.delegate = self;
		[webView loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
		[self addSubview:webView];
	}
	return self;
}

- (void)webViewDidFinishLoad:(UIWebView*)view
{
	view.hidden = NO;
}

- (void)resetScrolling
{
	[webView stringByEvaluatingJavaScriptFromString:@"scrollTo(0,0)"];
}

- (void)dealloc
{
	// Destroy the web view
	[webView release];

	// Destroy everything else
	[super dealloc];
}

@end
