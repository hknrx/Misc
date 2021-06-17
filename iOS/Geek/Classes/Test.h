#import <UIKit/UIKit.h>
#import "Slave.h"

#define answerCount 3

@interface Test : UIView <Slave>
{
	CGMutablePathRef sheetPath;
	CGMutablePathRef holesPath;
	CGMutablePathRef linesPath;
	CGMutablePathRef okPath;
	CGMutablePathRef errorPath;

	enum {FRONT_PAGE, QUESTION, ANSWER_OK, ANSWER_ERROR, LAST_PAGE} sheetState;

	unsigned char questionNumber;
	unsigned char questionIndex;
	unsigned char questionIncrement;
	UILabel* questionLabel;
	UILabel* questionText;
	UIButton* answer[answerCount];
	unsigned char answerCorrectNumber;
	unsigned short answerState;
}

+ (NSInteger)questionCountForTestCount:(NSInteger)testCount;
+ (NSString*)scoreForCorrectAnswerCount:(NSInteger)correctAnswerCount inTestCount:(NSInteger)testCount;

@end
