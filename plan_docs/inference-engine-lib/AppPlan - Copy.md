# Cross-Pltaform Inference Engine Library

- Hosts multi-platform inference capability, w/ HW accelleration autmoatically ewngaged on best effort basis.
- CHoose highest performance egnine available based on patform and available HW
- onnx runtime is used as the inference engine

* Depending on OS/Platform 

- When available, uses abvaialble o-device model and HW accleratrion based on GPU present (or CPU i+ RAM) if not.)
- Otherwise, resorts to fetching and setting up mopdel to use best effort HW accelerati dependent on asvaialble HW

### Examples

|OS ****| HW Available  |
|*******| NPU  |GPU|******|
|       |      |AMD|NVidia|
Windows | Yes  | Yes | Yes |
Linux   | Yes  | Yes | Yes |
Mac     | Yes  | Yes | Yes |    
WEB     | Yes  | Yes | Yes |    

## Operation

## Language & Framework
 .NET C# Library

## Use

### Integration
1. Take project reference
2. Extend InferenceEngine class
3. Implement abstract methods
4. Add any additional methods as needed
5. Create instance of InferenceEngine class
6. Use instance to run inference

### Requirements

Support Existing apps' requirements

<..\support-assistant\AppPlan.md>
<..\InferenceApp>

### Driver App

* Copy the InferenceApp to the driver app project
- Convert the InferenceApp to use the new InferneceEngine by sugrically repalcing the existing one.

