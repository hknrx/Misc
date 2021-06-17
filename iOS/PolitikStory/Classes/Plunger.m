#import "Plunger.h"
#import "Vote.h"
#import "Candidate.h"

@interface Plunger ()
{
	Vote * vote;
}

@end

@implementation Plunger

@synthesize touch;
@synthesize initCenter;
@synthesize touchedCandidate;

- (id)initWithVote:(Vote *)_vote
{
	self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 45.0f)];
	if(self)
	{
		self.userInteractionEnabled = YES;
		self.contentMode = UIViewContentModeCenter;
		self.image = [UIImage imageNamed:@"Plunger_Out.png"];
		self.highlightedImage = [UIImage imageNamed:@"Plunger_In.png"];
		vote = _vote;
	}
	return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(!touch)
	{
		touch = [touches anyObject];
		[vote plungerTouchBegan:self];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if([touches containsObject:touch])
	{
		[vote plungerTouchMoved:self];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if([touches containsObject:touch])
	{
		[vote plungerTouchEnded:self];
		touch = nil;
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	if([touches containsObject:touch])
	{
		[vote plungerTouchCancelled:self];
		touch = nil;
	}
}

@end
