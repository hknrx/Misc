#import "Vote.h"
#import "ViewController.h"
#import "Candidate.h"
#import "Plunger.h"
#import "Button.h"
#import "AlertBox.h"
#import "ScrollingMessage.h"

@interface Vote ()
{
	ViewController * viewController;
	UIScrollView * scrollView;
	int scrollViewDisableCounter;
	Plunger * plungers[PLUNGERS_COUNT];
}

@end

@implementation Vote

static NSString *const helpTextVote = @"Vous ne souhaitez pas qu'ils poursuivent l'aventure ? Votez contre eux et sortez-les !! Glissez-déposez les ventouses sur les photos des candidats que vous n'aimez pas, puis votez ! (1 ventouse compte pour 1 vote ; plusieurs ventouses peuvent être mises sur une seule et même photo !)";
static NSString *const candidateNames[CANDIDATES_COUNT] =
{
	@"LePen",
	@"Sarkozy",
	@"Bayrou",
	@"Hollande",
	@"Joly",
	@"Melenchon",
};
static CGPoint const plungerTouchTranslate = {0.0f, -30.0f};
static CGPoint const plungerOutHead = {-5.0f, -2.0f};
static CGPoint const plungerInHead = {-3.0f, -1.0f};

- (id)initWithViewController:(ViewController *)_viewController
{
	self = [super initWithImage:[UIImage imageNamed:@"Background_Vote.png"]];
	if(self)
	{
		self.userInteractionEnabled = YES;
		viewController = _viewController;

		UIButton * button = [Button createButtonWithBackground:[UIImage imageNamed:@"Button_Small.png"] withIcon:[UIImage imageNamed:@"Icon_CancelVote.png"] withText:@"Annuler" ofSize:12.0f withSpacing:10.0f];
		button.center = CGPointMake((button.frame.size.width - button.frame.size.height) / 2 + 20.0f, 20.0f);
		[button addTarget:self action:@selector(voteCancel) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:button];

		button = [Button createButtonWithBackground:[UIImage imageNamed:@"Button_Small.png"] withIcon:[UIImage imageNamed:@"Icon_DidVote.png"] withText:@"A voté !" ofSize:12.0f withSpacing:10.0f];
		button.center = CGPointMake(self.frame.size.width - (button.frame.size.width - button.frame.size.height) / 2 - 20.0f, 20.0f);
		[button addTarget:self action:@selector(voteDo) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:button];

		scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, 40.0f, 480.0f, 244.0f)];
		scrollView.showsHorizontalScrollIndicator = NO;
		[self addSubview:scrollView];

		NSDictionary * resultsData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"results"];
		Candidate * candidates[CANDIDATES_COUNT];
		CGRect candidateFrame = CGRectMake(0.0f, 0.0f, 140.0f, 244.0f);
		for(int candidateId = 0; candidateId < CANDIDATES_COUNT; ++candidateId)
		{
			if([[resultsData valueForKey:[NSString stringWithFormat:@"candidate_%d", candidateId]] intValue] >= 0)
			{
				candidates[candidateId] = [[Candidate alloc] initWithFrame:candidateFrame withName:candidateNames[candidateId]];
				candidates[candidateId].tag = candidateId;
				[scrollView insertSubview:candidates[candidateId] atIndex:0];
				candidateFrame.origin.x += candidateFrame.size.width;
			}
		}

		UIView * plungerBox = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PlungerBox.png"]];
		plungerBox.center = CGPointMake(self.bounds.size.width - plungerBox.frame.size.width / 2, 162.5f);
		[self addSubview:plungerBox];

		NSDictionary * voteData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"vote"];
		CGFloat const height = plungerBox.frame.size.height / PLUNGERS_COUNT;
		CGPoint plungerCenter = CGPointMake(plungerBox.center.x, plungerBox.frame.origin.y + height / 2);
		for(int plungerId = 0; plungerId < PLUNGERS_COUNT; ++plungerId)
		{
			Plunger * plunger = [[Plunger alloc] initWithVote:self];
			plunger.initCenter = plungerCenter;
			id plungerData;
			id plungerCandidateIdObject;
			unsigned int plungerCandidateId;
			id plungerCenterX;
			id plungerCenterY;
			if(voteData
			   && [(plungerData = [voteData objectForKey:[NSString stringWithFormat:@"plunger_%d", plungerId]]) isKindOfClass:[NSDictionary class]]
			   && [(plungerCandidateIdObject = [plungerData valueForKey:@"candidate_id"]) isKindOfClass:[NSNumber class]]
			   && (plungerCandidateId = [plungerCandidateIdObject intValue]) < CANDIDATES_COUNT
			   && [[resultsData valueForKey:[NSString stringWithFormat:@"candidate_%d", plungerCandidateId]] intValue] >= 0
			   && [(plungerCenterX = [plungerData valueForKey:@"center_x"]) isKindOfClass:[NSNumber class]]
			   && [(plungerCenterY = [plungerData valueForKey:@"center_y"]) isKindOfClass:[NSNumber class]])
			{
				plunger.highlighted = YES;
				plunger.center = CGPointMake([plungerCenterX floatValue], [plungerCenterY floatValue]);
				[candidates[plungerCandidateId] addSubview:plunger];
			}
			else
			{
				plunger.center = plungerCenter;
				[self addSubview:plunger];
			}
			plungerCenter.y += height;
			plungers[plungerId] = plunger;
		}

		scrollView.contentSize = CGSizeMake(candidateFrame.origin.x + plungerBox.frame.size.width, candidateFrame.size.height);
		if(scrollView.bounds.size.width > scrollView.contentSize.width)
		{
			candidateFrame = scrollView.bounds;
			candidateFrame.size.width = scrollView.contentSize.width;
			scrollView.bounds = candidateFrame;
		}

		ScrollingMessage * help = [[ScrollingMessage alloc] initWithFrame:self.frame];
		help.text = helpTextVote;
		[self addSubview:help];
	}
	return self;
}

- (void)voteCancel
{
	UIView * mask = [[UIView alloc] initWithFrame:self.frame];
	mask.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
	[self addSubview:mask];

	AlertBox * alertBox = [[AlertBox alloc] initWithFirstLabel:@"Ok, tes choix précédents" andSecondLabel:@"sont conservés..." andButtonLabel:@"Résultats" andButtonIcon:[UIImage imageNamed:@"Icon_GoResults.png"] andBlock:^{
		[viewController displayResultsScreen];
	}];
	[self addSubview:alertBox];

	mask.alpha = 0.0f;
	alertBox.center = CGPointMake(self.center.x, -alertBox.frame.size.height / 2);
	[UIView animateWithDuration:0.5
					 animations:^{
						 mask.alpha = 1.0f;
						 alertBox.center = self.center;
					 }];
}

- (NSDictionary *)voteData
{
	NSMutableDictionary * data = [NSMutableDictionary dictionaryWithCapacity:PLUNGERS_COUNT];
	for(int plungerId = 0; plungerId < PLUNGERS_COUNT; ++plungerId)
	{
		if([plungers[plungerId].superview isKindOfClass:[Candidate class]])
		{
			NSDictionary * plungerData = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:plungers[plungerId].superview.tag], @"candidate_id", [NSNumber numberWithFloat:plungers[plungerId].center.x], @"center_x", [NSNumber numberWithFloat:plungers[plungerId].center.y], @"center_y", nil];
			[data setValue:plungerData forKey:[NSString stringWithFormat:@"plunger_%d", plungerId]];
		}
	}
	return data;
}

- (void)voteDo
{
	UIView * mask = [[UIView alloc] initWithFrame:self.frame];
	mask.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
	[self addSubview:mask];

	UIActivityIndicatorView * activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activityIndicator.center = mask.center;
	[activityIndicator startAnimating];
	[mask addSubview:activityIndicator];

	void (^blockVoteDo)(BOOL error) = ^(BOOL error)
	{
		[activityIndicator removeFromSuperview];

		UIView * __block alertBox;
		if(error)
		{
			alertBox = [[AlertBox alloc] initWithFirstLabel:@"Erreur !" andSecondLabel:@"Problème de connexion !" andButtonLabel:@"OK" andButtonIcon:nil andBlock:^{
				[UIView animateWithDuration:0.5
				 				 animations:^{
									 mask.alpha = 0.0f;
									 alertBox.center = CGPointMake(self.center.x, -alertBox.frame.size.height / 2);
								 }
								 completion:^(BOOL finished){
									 [mask removeFromSuperview];
									 [alertBox removeFromSuperview];
								 }];
			}];
		}
		else
		{
			alertBox = [[AlertBox alloc ] initWithFirstLabel:@"Ton vote a bien été pris" andSecondLabel:@"en compte citoyen !" andButtonLabel:@"Résultats" andButtonIcon:[UIImage imageNamed:@"Icon_GoResults.png"] andBlock:^{
				[viewController displayResultsScreen];
			}];
			[self addSubview:alertBox];
		}
		[self addSubview:alertBox];

		alertBox.center = CGPointMake(self.center.x, -alertBox.frame.size.height / 2);
		[UIView animateWithDuration:0.5
						 animations:^{
							 alertBox.center = self.center;
						 }];
	};

	mask.alpha = 0.0f;
	[UIView animateWithDuration:0.5
					 animations:^{
						 mask.alpha = 1.0f;
					 }
					 completion:^(BOOL finished){
						 [viewController voteWithData:[self voteData] withBlock:blockVoteDo];
					 }];
}

- (void)plungerTouchBegan:(Plunger *)plunger
{
	scrollView.scrollEnabled = !++scrollViewDisableCounter;

	if([plunger.superview isKindOfClass:[Candidate class]])
	{
		plunger.highlighted = NO;
		[plunger.superview setNeedsDisplay];
	}

	[self addSubview:plunger];
	[self plungerTouchMoved:plunger];
}

- (void)plungerTouchMoved:(Plunger *)plunger
{
	CGPoint center = [plunger.touch locationInView:scrollView];
	center.x += plungerTouchTranslate.x;
	center.y += plungerTouchTranslate.y;

	UIView * touchedView = [scrollView hitTest:center withEvent:nil];
	if(touchedView != plunger.touchedCandidate)
	{
		plunger.touchedCandidate.blendColor = nil;
		if([touchedView isKindOfClass:[Candidate class]])
		{
			plunger.touchedCandidate = (Candidate *)touchedView;
			plunger.touchedCandidate.blendColor = [UIColor colorWithRed:1.0f green:0.2f blue:0.2f alpha:0.8f];
		}
		else
		{
			plunger.touchedCandidate = nil;
		}
	}

	center = [plunger.touch locationInView:self];
	center.x += plungerTouchTranslate.x - plungerOutHead.x;
	center.y += plungerTouchTranslate.y - plungerOutHead.y;
	plunger.center = center;
}

- (void)plungerTouchEnded:(Plunger *)plunger
{
	if(plunger.touchedCandidate)
	{
		CGPoint center = [plunger.touchedCandidate convertPoint:plunger.center fromView:self];
		center.x += plungerOutHead.x - plungerInHead.x;
		center.y += plungerOutHead.y - plungerInHead.y;

		plunger.highlighted = YES;
		plunger.center = center;
		[plunger.touchedCandidate addSubview:plunger];
		plunger.touchedCandidate.blendColor = nil;
		plunger.touchedCandidate = nil;
	}
	else
	{
		plunger.center = plunger.initCenter;
	}
	scrollView.scrollEnabled = !--scrollViewDisableCounter;
}

- (void)plungerTouchCancelled:(Plunger *)plunger
{
	plunger.touchedCandidate.blendColor = nil;
	plunger.touchedCandidate = nil;
	plunger.center = plunger.initCenter;

	scrollView.scrollEnabled = !--scrollViewDisableCounter;
}

@end
