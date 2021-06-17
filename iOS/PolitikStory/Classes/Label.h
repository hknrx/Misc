@interface Label : UILabel
{
	UIColor * outlineColor;
	BOOL glow;
}

@property (nonatomic, strong) UIColor * outlineColor;
@property (nonatomic) BOOL glow;

@end
