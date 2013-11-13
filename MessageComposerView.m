// MessageComposerView.m
//
// Copyright (c) 2013 oseparovic. ( http://thegameengine.org )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MessageComposerView.h"

@interface MessageComposerView()
@property(nonatomic, strong) IBOutlet UITextView *messageTextView;
@property(nonatomic, strong) IBOutlet UIButton *sendButton;
@end

@implementation MessageComposerView

const int kComposerBackgroundTopPadding = 10;
const int kComposerBackgroundRightPadding = 10;
const int kComposerBackgroundBottomPadding = 10;
const int kComposerBackgroundLeftPadding = 10;
const int kComposerTextViewButtonBetweenPadding = 10;

// Default animation time for 5 <= iOS < 7. Used as a default but should be overwritten by first keyboard notification.
float keyboardAnimationDuration = 0.25;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        // TODO: initializing programatically, instead of from the XIB for some reason causes self.frame to NOT yet be resized at the point when
        // a UIDeviceOrientationDidChangeNotification notification is caught. Initializing from the NIB has the opposite behaviour. Could be
        // something to do with the autoresizingMask or a property not transferred over from the XIB...
        self.frame = frame;
        self.backgroundColor = [UIColor lightGrayColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = NO;
        
        CGRect sendButtonFrame = CGRectZero;
        sendButtonFrame.size.width = 50;
        sendButtonFrame.size.height = 34;
        sendButtonFrame.origin.x = frame.size.width - kComposerBackgroundRightPadding - sendButtonFrame.size.width;
        sendButtonFrame.origin.y = kComposerBackgroundRightPadding;
        self.sendButton = [[UIButton alloc] initWithFrame:sendButtonFrame];
        self.sendButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        self.sendButton.layer.cornerRadius = 5;
        [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.sendButton setTitleColor:[UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1.0] forState:UIControlStateHighlighted];
        [self.sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
        [self.sendButton setBackgroundColor:[UIColor orangeColor]];
        [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
        self.sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [self addSubview:self.sendButton];
        
        CGRect messageTextViewFrame = CGRectZero;
        messageTextViewFrame.origin.x = kComposerBackgroundLeftPadding;
        messageTextViewFrame.origin.y = kComposerBackgroundTopPadding;
        messageTextViewFrame.size.width = frame.size.width - kComposerBackgroundLeftPadding - kComposerTextViewButtonBetweenPadding - sendButtonFrame.size.width - kComposerBackgroundRightPadding;
        messageTextViewFrame.size.height = 34;
        self.messageTextView = [[UITextView alloc] initWithFrame:messageTextViewFrame];
        self.messageTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        self.messageTextView.showsHorizontalScrollIndicator = NO;
        self.messageTextView.layer.cornerRadius = 5;
        self.messageTextView.font = [UIFont systemFontOfSize:14];
        self.messageTextView.delegate = self;
        [self addSubview:self.messageTextView];
        
        [self addNotifications];
        [self resizeTextViewForText:@"" animated:NO];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)dealloc {
    [self removeNotifications];
}

- (void)setup {
    [self addNotifications];
    
    self.sendButton.layer.cornerRadius = 5;
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1.0] forState:UIControlStateHighlighted];
    [self.sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
    [self.sendButton setBackgroundColor:[UIColor orangeColor]];

    self.messageTextView.showsHorizontalScrollIndicator = NO;
    self.messageTextView.layer.cornerRadius = 5;
    [self resizeTextViewForText:@"" animated:NO];
}


#pragma mark - NSNotification
- (void)addNotifications {
    NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(textViewTextDidChange:) name:UITextViewTextDidChangeNotification object:self.messageTextView];
    [defaultCenter addObserver:self selector:@selector(handleRotation:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)removeNotifications {
    NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self name:UITextViewTextDidChangeNotification object:self.messageTextView];
    [defaultCenter removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [defaultCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}


#pragma mark - UITextViewDelegate
- (void)textViewTextDidChange:(NSNotification*)notification {
    NSString* newText = self.messageTextView.text;
    [self resizeTextViewForText:newText animated:YES];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(messageComposerUserTyping)])
        [self.delegate messageComposerUserTyping];
}

- (void)textViewDidBeginEditing:(UITextView*)textView {
    CGRect frame = self.frame;
    frame.origin.y = ([self currentScreenHeight] - [self currentKeyboardHeight]) - frame.size.height;
    
    [UIView animateWithDuration:keyboardAnimationDuration animations:^{
        self.frame = frame;
    }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageComposerFrameDidChange:withAnimationDuration:)]) {
        [self.delegate messageComposerFrameDidChange:frame withAnimationDuration:keyboardAnimationDuration];
    }
}

- (void)textViewDidEndEditing:(UITextView*)textView {
    CGRect frame = self.frame;
    frame.origin.y = [self currentScreenHeight] - self.frame.size.height;
    
    [UIView animateWithDuration:keyboardAnimationDuration animations:^{
        self.frame = frame;
    }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageComposerFrameDidChange:withAnimationDuration:)]) {
        [self.delegate messageComposerFrameDidChange:frame withAnimationDuration:keyboardAnimationDuration];
    }
}


#pragma mark - Rotation
- (void)handleRotation:(NSNotification*)notification {
    if ([self.messageTextView isFirstResponder]) {
        CGRect frame = self.frame;
        frame.origin.y = ([self currentScreenHeight] - [self currentKeyboardHeight]) - frame.size.height;
        self.frame = frame;
        
        // After rotating we want to make sure that the UITextView tightly wraps the text so we resize it. In this
        // case we don't want to animate because we're already animating as part of the the rotation and don't want
        // to overload the animation and make it look like someone is shuffling a deck of cards.
        [self resizeTextViewForText:self.messageTextView.text animated:NO];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(messageComposerFrameDidChange:withAnimationDuration:)]) {
            [self.delegate messageComposerFrameDidChange:self.frame withAnimationDuration:keyboardAnimationDuration];
        }
    }
}


#pragma mark - Keyboard Notifications
- (void)keyboardWillShow:(NSNotification*)notification {
    // Because keyboard animation time varies by iOS version, and we don't want to build the library
    // on top of spammy keyboard notifications we use UIKeyboardWillShowNotification ONLY to dynamically set our
    // animation duration. As a UIKeyboardWillShowNotification is fired BEFORE textViewDidBeginEditing
    // is triggered we can use the following value for all of animations including the first.
    keyboardAnimationDuration = [[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] floatValue];
}


#pragma mark - TextView Frame Manipulation
- (void)resizeTextViewForText:(NSString*)text {
    [self resizeTextViewForText:text animated:NO];
}

- (void)resizeTextViewForText:(NSString*)text animated:(BOOL)animated {
    CGFloat fixedWidth = self.messageTextView.frame.size.width;
    CGSize oldSize = self.messageTextView.frame.size;
    CGSize newSize = [self.messageTextView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    
    // If the height doesn't need to change skip reconfiguration
    if (oldSize.height == newSize.height) {
        return;
    }
    
    // Recalculate composer view container frame
    CGRect newContainerFrame = self.frame;
    newContainerFrame.size.height = newSize.height + kComposerBackgroundTopPadding + kComposerBackgroundBottomPadding;
    newContainerFrame.origin.y = ([self currentScreenHeight] - [self currentKeyboardHeight]) - newContainerFrame.size.height;
    
    // Recalculate send button frame
    CGRect newSendButtonFrame = self.sendButton.frame;
    newSendButtonFrame.origin.y = newContainerFrame.size.height - (kComposerBackgroundBottomPadding + newSendButtonFrame.size.height);
    
    
    // Recalculate UITextView frame
    CGRect newTextViewFrame = self.messageTextView.frame;
    newTextViewFrame.size.height = newSize.height;
    newTextViewFrame.origin.y = kComposerBackgroundTopPadding;
    
    if (animated) {
        [UIView animateWithDuration:keyboardAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.frame = newContainerFrame;
                             self.sendButton.frame = newSendButtonFrame;
                             self.messageTextView.frame = newTextViewFrame;
                             [self.messageTextView setContentOffset:CGPointMake(0, 0) animated:YES];
                         }
                         completion:nil];
    } else {
        self.frame = newContainerFrame;
        self.sendButton.frame = newSendButtonFrame;
        self.messageTextView.frame = newTextViewFrame;
        [self.messageTextView setContentOffset:CGPointMake(0, 0) animated:YES];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageComposerFrameDidChange:withAnimationDuration:)]) {
        [self.delegate messageComposerFrameDidChange:newContainerFrame withAnimationDuration:keyboardAnimationDuration];
    }
}

- (void)scrollTextViewToBottom {
    [self.messageTextView scrollRangeToVisible:NSMakeRange([self.messageTextView.text length], 0)];
}


#pragma mark - IBAction
- (IBAction)sendClicked:(id)sender {
    if(self.delegate) {
        [self.delegate messageComposerSendMessageClickedWithMessage:self.messageTextView.text];
    }
    
    if ([self.messageTextView isFirstResponder]) {
        [self.messageTextView setText:@""];
    } else {
        [self.messageTextView setText:@""];
        // Manually trigger the textViewDidChange method as setting the text when the messageTextView is not first responder the
        // UITextViewTextDidChangeNotification notification does not get fired.
        [self textViewTextDidChange:nil];        
    }
}


#pragma mark - Utils
- (UIInterfaceOrientation)currentOrientation {
    return [UIApplication sharedApplication].statusBarOrientation;
}

- (float)currentKeyboardHeight {
    float keyboardHeight;
    // TODO: this is very bad... another solution is need or this will break on internation keyboards etc.
    if (UIInterfaceOrientationIsPortrait([self currentOrientation])) {
        keyboardHeight = 216;
    } else {
        keyboardHeight = 162;
    }
    return keyboardHeight;
}

- (float)currentScreenHeight {
    return [self sizeInOrientation:[self currentOrientation]].height;
}

- (CGSize) sizeInOrientation:(UIInterfaceOrientation)orientation {
    // http://stackoverflow.com/a/7905540/740474
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIApplication *application = [UIApplication sharedApplication];
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        size = CGSizeMake(size.height, size.width);
    }
    if (application.statusBarHidden == NO) {
        size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    }
    return size;
}

- (void)startEditing {
    [self.messageTextView becomeFirstResponder];
}

- (void)finishEditing {
    [self.messageTextView resignFirstResponder];
}
@end
