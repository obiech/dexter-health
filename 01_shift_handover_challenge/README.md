# Senior Mobile Developer Coding Challenge: Shift Handover Feature

Welcome to the coding challenge! This exercise is designed to assess your understanding of software architecture, state management, and testing in a Flutter environment.

## The Scenario

You've been tasked with improving a new feature in the `dexter_health` application: the **Shift Handover Assistant**. This feature is intended to allow caregivers to create a simple report of events from their shift to hand over to the next caregiver.

The initial version of this feature was built quickly to get feedback and, as a result, it has several problems. Your job is to refactor it into a high-quality, maintainable, and testable feature.

### Core Requirements

You should focus on the following areas. You are required to improve the quality of the existing and complete the shift handover feature, ensuring all CRUD operations are functional and data is only stored in-memory.

- **Immutable Data Models:** Ensure all data models in the application are immutable.

- **Clean Architecture & Dependency Injection:** Refactor the project to follow Clean Architecture principles. Use and Dependency Injection of your choice.

- **Error Handling:** Implement error handling techniques to gracefully manage failures (e.g., network errors, business logic errors).

- **Unit Testing:** Write unit tests that cover your implementation of the service layer.

- **Integration Testing:** Write integration tests that cover the entire feature usage, from the screens, down through the widgets, BLoC, and service layer.

## How to Submit
1. Create a public GitHub repository for your solution.
2. Push your changes before the 4 hour deadline.
3. Include a **Solution.md** file with the following:
   - A brief description for each of the issues you found.
   - The steps you took to fix each issue.
   - Any additional notes or considerations regarding the fixes.
4. Share the repository link with us.

## Final Notes

*   Feel free to use any packages you see fit, but try to stick to the patterns already present in the codebase.
*   You can also add comments in your code to explain your decisions.
*   The `ShiftHandoverService` is a fake service. You don't need to implement a real backend, data should be stored in memory.

Good luck!