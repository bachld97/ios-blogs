# Objective-C learning

## Class declaration

In Objective-C, each class is created using 2 files `*.m` and `*.h`.
In `.h`, we create the header, and in `.m` we create the implementation

```objc
// ExampleClass.h
@interface ExampleClass: NSObject 
// Public methods and properties declaration
@end

// ExampleClass.m
@interface Example ()
// Private methods and properties declaration
@end

@implementation ExampleClass 
// Implementation here
@end
```

## Properties declaration

Properties must be declared within the 2 `@interface` above.
The code below illustrate how to create a string.

```objc
@property (nonatomic, strong) NSString *stringName;
```

The general syntax:
```
@property (attributes) Type name;
```

### Property attributes

* atomic (default for pointer)
* assign (default for primitive)
* nonatomic
* nullable (default)
* nonnull
* readonly: Similar to private (set)
* strong (default for pointer)
* weak
* readwrite (default)

Attributes are grouped as follows:

* atomic/nonatomic
* strong/weak/assign/copy
* readwrite/readonly
* nullable/nonnull

`copy` is typically used for `NSString`, `NSArray`, and `NSDictionary` to avoid issues when assigned the mutable variant. 
This avoids problem of value being changed unexpectedly.

### didSet and willSet

```objc
- (void)setSomething:(type)something {
    // willSet
    _something = something;
    // didSet
}
```

## Function declaration

Side-by-side declaration of swift and objc

In swift,

```swift
func doSomething(var1: Type1, namedVar2 var2: Type2, var3: Type3) -> ReturnType { }
```

and objective-C counterpart

```objc
- (ReturnType)doSomethingWithVar1:(Type1)var1 namedVar:(Type2)var2 :(Type3)var3 { }
```

Call site

```swift
// Swift
self.doSomething(var1: v1, namedVar2: v2, var3: v3)
```

```objc
// Objective-C
[self doSomethingWithVar1:v1 namedVar2:v2 :v3];
```

Static/Class properties
```swift
// Declaration
+ (void) classFuncStartWithPlus;

// Call site
[ClassName classFuncStartWithPlus];
```

## Protocol declaration and comformance

```objc
// Declaration
@protocol ProtocolName
    @required
    ...
    @optional // Objective-C has optional conformance, but I do not find it useful
    ...
@end

// Conformance, in .h files
@interface ExampleClass : Inheritance <ProtocolName>

// Declaring property conforming to protocol
@property (nonatomic, nullable, weak) id<ProtocolName> someDelegate;

// Inside function
id<ProtocolName> var = self.someDelegate;
```

## Swift extension in ObjC

Extension feature in Swift is named category in objective-C

```objc
// .h
@interface UIView (AutoLayout)

- (void) anchorToTop:(nullable NSLayoutYAxisAnchor *)top
             leading:(nullable NSLayoutXAxisAnchor *)leading
              bottom:(nullable NSLayoutYAxisAnchor *)bottom
            trailing:(nullable NSLayoutXAxisAnchor* )trailing
             padding:(UIEdgeInsets)padding
                size:(CGSize)size;
@end


// .m
@implementation UIView (AutoLayout)
- (void) anchorToTop:(nullable NSLayoutYAxisAnchor *)top
             leading:(nullable NSLayoutXAxisAnchor *)leading
              bottom:(nullable NSLayoutYAxisAnchor *)bottom
            trailing:(nullable NSLayoutXAxisAnchor *)trailing
             padding:(UIEdgeInsets)padding
                size:(CGSize)size
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    if (top != nil) {
        [self.topAnchor constraintEqualToAnchor:top
                                       constant:padding.top
         ].active = YES;
    }
    if (leading != nil) {
        [self.leadingAnchor constraintEqualToAnchor:leading
                                           constant:padding.left
         ].active = YES;
    }
    if (bottom != nil) {
        [self.bottomAnchor constraintEqualToAnchor:bottom
                                          constant:-padding.bottom
         ].active = YES;
    }
    if (trailing != nil) {
        [self.trailingAnchor constraintEqualToAnchor:trailing
                                            constant:-padding.right
         ].active = YES;
    }
    if (size.width > 0) {
        [self.widthAnchor constraintEqualToConstant:size.width].active = YES;
    }
    if (size.height > 0) {
        [self.heightAnchor constraintEqualToConstant:size.height].active = YES;
    }
}
@end
```

To use category methods, remember to import category header files.

## Enums

Declare this in a header, and import such header in files that uses this enum.

```objc
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EnumTest) {
    EnumTestValue1, 
    EnumTestValue2,
}
```

Enum name prefix is important, it makes code readable and helps autocomplete.

## Forward declaration

Like C/C++, sometimes we need our header to declare a class in different headers.
However, importing the whole other headers are not efficient, we should use forward declaration instead.

```objc
@class ForwardDeclaredClass1, ForwardDeclaredClass2
```
