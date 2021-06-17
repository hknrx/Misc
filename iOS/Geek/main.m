/*
 TODO (TASKS):
 - N/A.

 TODO (OPTIONAL):
 - Implement a new funfair game: a maze (automatically generated) from which the player should try to exit by drawing a path (or press a button if he/she thinks there is no way to go through the maze?). The time would be limited, the timer being defined by the pathfinder (length of the shortest path multiplied by a coefficient).
 - Add questions to the Nerd Test.
 - Adjust the scoring of the 2 funfair games so that they appear to be well balanced...
 - Add a new entry "Physics engine", under which one would find "Jelly Beans" and "Photo Bubble Lite" (just 1 bubble for the photo and a rock to "get the full version")... An animated Foucault pendulum would be displayed on the menu.
 - Stack Game & Time Master: add sound effects.
 - Dance Floor: make the dancer go back to the initial (rest) state when there is no beat.
 - Implement other games ("Lighthouse", "Flamin Finger", ...)?
 - Implement other applications (e.g. a photo/ASCII art converter, etc.).
 */

#import <UIKit/UIKit.h>

int main(int argc, char* argv[])
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, nil, @"ApplicationDelegate");
	[pool release];
	return retVal;
}
