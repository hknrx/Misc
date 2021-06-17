@class Vote;
@class Candidate;

@interface Plunger : UIImageView

- (id)initWithVote:(Vote *)vote;

@property (nonatomic) CGPoint initCenter;
@property (nonatomic, unsafe_unretained, readonly) UITouch * touch;
@property (nonatomic, unsafe_unretained) Candidate * touchedCandidate;

@end
