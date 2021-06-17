#import "Results.h"
#import "ViewController.h"
#import "Label.h"
#import "Button.h"
#import "AlertBox.h"
#import "ScrollingMessage.h"

@interface Results ()
{
	ViewController * viewController;
	Label * results[CANDIDATES_COUNT];
	UIImageView * noteEvicted[CANDIDATES_COUNT];
	Label * count;
	UIImageView * noteKickOut;
	UIImageView * noteSheepRebel;
	UIView * mask;
}

- (void)animate;
- (void)displayResults;

@end

@implementation Results

static NSString *const helpTextResults = @"Mouton ou rebelle, exprimez-vous ! Pas de SMS surtaxé, votez simplement en ligne et suivez l'évolution des résultats en temps réel ! Surtout, n'oubliez pas la demie-finale, en direct le 22 avril, et ne ratez pas la grande finale lors du prime du 6 mai ! Il n'en restera qu'un(e) !!";
static BOOL const candidateIsFemale[CANDIDATES_COUNT] = {YES, NO, NO, NO, YES, NO};
static CGPoint const noteSheepRebelAnchor = {37.0f, 27.0f};
static CGPoint const noteSheepRebelCenter = {470.0f, 274.0f};
static CGFloat const noteSheepRebelAngleMin = -8.0f * M_PI / 180.0f;
static CGFloat const noteSheepRebelAngleMax = -12.0f * M_PI / 180.0f;

- (id)initWithViewController:(ViewController *)_viewController
{
	self = [super initWithImage:[UIImage imageNamed:@"Background_Results.png"]];
	if(self)
	{
		self.userInteractionEnabled = YES;
		viewController = _viewController;

		UIButton * button = [Button createButtonWithBackground:[UIImage imageNamed:@"Button_Small.png"] withIcon:[UIImage imageNamed:@"Icon_RefreshResults.png"] withText:@"Mise à jour résultats" ofSize:10.0f withSpacing:5.0f];
		button.center = CGPointMake((button.frame.size.width - button.frame.size.height) / 2 + 20.0f, 20.0f);
		[button addTarget:self action:@selector(updateResults) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:button];

		button = [Button createButtonWithBackground:[UIImage imageNamed:@"Button_Small.png"] withIcon:[UIImage imageNamed:@"Icon_GoVote.png"] withText:@"Aux urnes citoyen !" ofSize:10.0f withSpacing:5.0f];
		button.center = CGPointMake(self.frame.size.width - (button.frame.size.width - button.frame.size.height) / 2 - 20.0f, 20.0f);
		[button addTarget:viewController action:@selector(displayVoteScreen) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:button];

		CGRect frame = CGRectMake(2.0f, 0.0f, 90.0f, 25.0f);
		UIImage * image = [UIImage imageNamed:@"Note_Evicted.png"];
		for(int candidateId = 0; candidateId < CANDIDATES_COUNT; ++candidateId)
		{
			Label * label = [[Label alloc] initWithFrame:frame];
			label.textAlignment = UITextAlignmentCenter;
			label.font = [UIFont fontWithName:@"Verdana-Bold" size:25.0f];
			[self addSubview:label];
			frame.origin.x += 78.0f;
			results[candidateId] = label;

			UIImageView * imageView = [[UIImageView alloc] initWithImage:image];
			imageView.center = CGPointMake(label.center.x, 160.0f);
			[self addSubview:imageView];
			noteEvicted[candidateId] = imageView;
		}

		count = [[Label alloc] initWithFrame:CGRectMake(5.0f, 279.0f - 16.0f, 130.0f, 16.0f)];
		count.font = [UIFont fontWithName:@"Verdana-Bold" size:12.0f];
		count.textColor = [UIColor whiteColor];
		count.outlineColor= [UIColor blueColor];
		count.glow = YES;
		[self addSubview:count];

		noteKickOut = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Note_KickOut_Male.png"] highlightedImage:[UIImage imageNamed:@"Note_KickOut_Female.png"]];
		noteKickOut.transform = CGAffineTransformMakeRotation(-12.0f * M_PI / 180.0f);
		[self addSubview:noteKickOut];

		noteSheepRebel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Note_Sheep.png"] highlightedImage:[UIImage imageNamed:@"Note_Rebel.png"]];
		noteSheepRebel.center = noteSheepRebelCenter;
		[self addSubview:noteSheepRebel];

		[self animate];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(animate) name:UIApplicationDidBecomeActiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateResults) name:UIApplicationDidBecomeActiveNotification object:nil];

		[self displayResults];

		ScrollingMessage * help = [[ScrollingMessage alloc] initWithFrame:self.frame];
		help.text = helpTextResults;
		[self addSubview:help];
	}
	return self;
}

- (void)animate
{
	count.transform = CGAffineTransformMakeTranslation(-1.0f, 0.0f);
	noteSheepRebel.transform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(noteSheepRebelAngleMin), -noteSheepRebelAnchor.x, -noteSheepRebelAnchor.y);
	[UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionRepeat|UIViewAnimationOptionAutoreverse
					 animations:^{
						 count.transform = CGAffineTransformMakeTranslation(1.0f, 0.0f);
						 noteSheepRebel.transform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(noteSheepRebelAngleMax), -noteSheepRebelAnchor.x, -noteSheepRebelAnchor.y);
					 }
					 completion:nil];
}

- (void)updateResults
{
	if(mask)
	{
		return;
	}

	mask = [[UIView alloc] initWithFrame:self.frame];
	mask.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
	[self addSubview:mask];

	UIActivityIndicatorView * activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activityIndicator.center = mask.center;
	[activityIndicator startAnimating];
	[mask addSubview:activityIndicator];

	void (^blockUpdateResults)(BOOL error) = ^(BOOL error)
	{
		if(error)
		{
			UIView * __block alertBox = [[AlertBox alloc] initWithFirstLabel:@"Erreur !" andSecondLabel:@"Problème de connexion !" andButtonLabel:@"OK" andButtonIcon:nil andBlock:^{
				[UIView animateWithDuration:0.5
				 				 animations:^{
									 alertBox.center = CGPointMake(self.center.x, -alertBox.frame.size.height / 2);
									 mask.alpha = 0.0f;
								 }
								 completion:^(BOOL finished){
									 [alertBox removeFromSuperview];
									 [mask removeFromSuperview];
									 mask = nil;
								 }];
			}];
			[self addSubview:alertBox];

			alertBox.center = CGPointMake(self.center.x, -alertBox.frame.size.height / 2);
			[UIView animateWithDuration:0.5
							 animations:^{
								 alertBox.center = self.center;
							 }];
		}
		else
		{
			[self displayResults];
			[UIView animateWithDuration:0.5
							 animations:^{
								 mask.alpha = 0.0f;
							 }
							 completion:^(BOOL finished){
								 [mask removeFromSuperview];
								 mask = nil;
							 }];
		}
	};

	mask.alpha = 0.0f;
	[UIView animateWithDuration:0.5
					 animations:^{
						 mask.alpha = 1.0f;
					 }
					 completion:^(BOOL finished){
						 [viewController updateResultsWithBlock:blockUpdateResults];
					 }];
}

- (void)clearResults
{
	count.hidden = YES;
	noteKickOut.hidden = YES;
	noteSheepRebel.hidden = YES;

	for(int candidateId = 0; candidateId < CANDIDATES_COUNT; ++candidateId)
	{
		Label * label = results[candidateId];
		label.text = @"?";
		label.textColor = [UIColor colorWithRed:0.8f green:0.8f blue:1.0f alpha:0.8f];
		label.outlineColor = nil;
		label.glow = NO;
		label.center = CGPointMake(label.center.x, 100.0f);

		noteEvicted[candidateId].hidden = YES;
	}
}

- (void)displayResults
{
	NSDictionary * resultsData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"results"];
	if(!resultsData)
	{
		[self clearResults];
		return;
	}

	int values[CANDIDATES_COUNT];
	int total = 0;
	int maxValue = 0;
	int maxId = 0;
	for(int candidateId = 0; candidateId < CANDIDATES_COUNT; ++candidateId)
	{
		int value = [[resultsData valueForKey:[NSString stringWithFormat:@"candidate_%d", candidateId]] intValue];
		values[candidateId] = value;
		if(value > 0)
		{
			total += value;
			if(maxValue < value)
			{
				maxValue = value;
				maxId = candidateId;
			}
		}
	}

	if(!total)
	{
		[self clearResults];
		return;
	}

	for(int candidateId = 0; candidateId < CANDIDATES_COUNT; ++candidateId)
	{
		Label * label = results[candidateId];
		UIImageView * imageView = noteEvicted[candidateId];
		if(values[candidateId] < 0)
		{
			label.hidden = YES;
			imageView.hidden = NO;
		}
		else
		{
			label.hidden = NO;
			imageView.hidden = YES;

			int value = 0.5f + values[candidateId] * 100.0f / total;
			label.text = [NSString stringWithFormat:@"%d%%", value];
			if(candidateId == maxId)
			{
				label.textColor = [UIColor redColor];
				label.outlineColor = [UIColor colorWithWhite:1.0f alpha:0.9f];
				label.glow = NO;
				label.center = CGPointMake(label.center.x, 100.0f - 8.0f);

				noteKickOut.center = CGPointMake(label.center.x, 130.0f);
				noteKickOut.highlighted = candidateIsFemale[candidateId];
				noteKickOut.hidden = NO;
			}
			else
			{
				label.textColor = [UIColor whiteColor];
				label.outlineColor = [UIColor yellowColor];
				label.glow = YES;
				label.center = CGPointMake(label.center.x, 100.0f);
			}
		}
	}

	int countValue = [[resultsData valueForKey:@"count"] intValue];
	count.text = [NSString stringWithFormat:@"%d votant%@ !", countValue, countValue > 1 ? @"s" : @""];
	count.hidden = NO;

	NSDictionary * voteData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"vote"];
	if(!voteData)
	{
		noteSheepRebel.hidden = YES;
	}
	else
	{
		int localValues[CANDIDATES_COUNT] = {0, 0, 0, 0, 0, 0};
		int localTotal = 0;
		for(int plungerId = 0; plungerId < PLUNGERS_COUNT; ++plungerId)
		{
			id plungerData;
			id candidateIdObject;
			unsigned int candidateId;
			if([(plungerData = [voteData objectForKey:[NSString stringWithFormat:@"plunger_%d", plungerId]]) isKindOfClass:[NSDictionary class]]
			   && [(candidateIdObject = [plungerData valueForKey:@"candidate_id"]) isKindOfClass:[NSNumber class]]
			   && (candidateId = [candidateIdObject intValue]) < CANDIDATES_COUNT
			   && values[candidateId] >= 0)
			{
				++localValues[candidateId];
				++localTotal;
			}
		}
		if(!localTotal)
		{
			noteSheepRebel.hidden = YES;
		}
		else
		{
			float average = (float)total / CANDIDATES_COUNT;
			float localAverage = (float)localTotal / CANDIDATES_COUNT;
			float sumA = 0.0f;
			float sumB = 0.0f;
			float sumC = 0.0f;
			for(int candidateId = 0; candidateId < CANDIDATES_COUNT; ++candidateId)
			{
				if(values[candidateId] >= 0)
				{
					float diff = values[candidateId] - average;
					float localDiff = localValues[candidateId] - localAverage;
					sumA += diff * localDiff;
					sumB += diff * diff;
					sumC += localDiff * localDiff;
				}
			}
			float correlation = fabsf(sumA / sqrtf(sumB * sumC));
#ifdef DEBUG
			NSLog(@"Correlation: %f", correlation);
#endif
			noteSheepRebel.hidden = correlation > 0.4f && correlation < 0.6f;
			noteSheepRebel.highlighted = correlation < 0.5f;
		}
	}
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
