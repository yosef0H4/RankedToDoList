# Gamified Ranked Todo App ✅🎯

## Overview

Ranked Todo App is a Flutter application designed to make task management more engaging and motivating. It combines traditional to-do list functionalities with gamification elements like points, ranks, and progress tracking. Users can create hierarchical tasks, set deadlines, assign rarities, and see their "MMR" (Matchmaking Rating) and rank evolve as they complete or fail tasks.

## Features 🌟

*   **🌳 Hierarchical Task Management:**
    *   Create tasks with sub-tasks to any depth.
    *   Define a root task (e.g., "Daily Goals").
    *   Set deadlines for tasks, with an option to inherit from parent tasks.
    *   Track task status: Not Started, Completed, or Failed.
*   **🎨 Task Customization:**
    *   **Task Rarity:** Assign different rarities (Common, Uncommon, Rare, Epic, Legendary, Mythic) to tasks, influencing their point value.
    *   **Rotating Tasks 🔄:** Create tasks with a list of sub-tasks that become active one by one, either daily or by manual advancement. Ideal for recurring routines.
*   **🎮 Gamification System:**
    *   **MMR & Ranks 🏆:** Earn or lose MMR points for completing or failing tasks. Progress through ranks: Bronze, Silver, Gold, Platinum, Diamond, Master, GrandMaster.
    *   **Dynamic Thresholds 📈:** The points required to reach the next rank are dynamically calculated based on the total value of all existing tasks.
    *   **Point Mechanics 💯:** Points awarded/deducted consider task rarity and the user's current rank.
*   **📱 User Interface:**
    *   **Dashboard:** Displays active, upcoming leaf tasks sorted by deadline, providing a quick overview of immediate priorities.
    *   **Task Tree View:** Visualizes the entire task hierarchy, allowing for easy navigation, expansion/collapse of sub-tasks, and management.
    *   **Undo/Redo ↩️↪️:** Robust undo/redo system (up to 20 actions) for most task operations.
    *   **Responsive Design:** UI adapts to different screen sizes using `flutter_screenutil`.
*   **💾 Data Management:**
    *   **Local Persistence:** All user data (tasks, rank, MMR) is automatically saved locally to a JSON file.
    *   **Backup & Restore:** Export user data to a JSON string for backup and restore from a previously saved backup.
*   **⏰ Deadline Management:**
    *   Automatic periodic checking of task deadlines.
    *   Tasks are automatically marked as failed if their deadline passes and they are not completed.
    *   Root tasks can reset their sub-tasks and create a new deadline (e.g., daily reset for daily tasks).

## Key Concepts & Mechanics ⚙️

*   **🌳 Task Hierarchy:** Tasks are organized in a tree structure. `RootTask` is the top-level container. `Task` objects can have parents and sub-tasks.
*   **🔄 Rotating Tasks (`RotatingTask`):** A special type of `Task` where only one of its sub-tasks is "active" at a time. Upon completion, it can advance to the next sub-task in its list. This is useful for daily routines or cyclical activities.
*   **💎 Task Rarity & Value:** Each task has a rarity which multiplies its base point value. The `UserRank` system calculates a dynamic threshold for rank progression based on the total "value" of all tasks, making progression relative to the user's current workload.
*   **🏆 MMR & Ranking:**
    *   Completing tasks awards MMR points; failing tasks or missing deadlines deducts MMR.
    *   The amount of MMR gained/lost is influenced by the task's rarity and the user's current rank (e.g., higher ranks might gain fewer points for common tasks or lose more for failures).
*   **🏗️ Command Pattern:** Core operations like adding, deleting, updating tasks, and changing task statuses are implemented using the Command pattern (`core/command.dart`, `core/commands.dart`). This enables the undo/redo functionality.
*   **📊 Provider State Management:** `UserProvider` (`providers/user_provider.dart`) serves as the central state manager, handling user data, task operations, and the undo/redo stacks.
*   **⏰ Deadline System:**
    *   The `DeadlineCheckMixin` is used in screens to periodically trigger deadline checks.
    *   `TaskBase` and its subclasses handle logic for updating status on deadline, and `RootTask` can reset its children.


## Tech Stack & Key Dependencies 💻📦

*   **Flutter SDK**
*   **Provider:** For state management.
*   **flutter_screenutil:** For responsive UI design.
*   **logger:** For application logging.
*   **intl:** For date and time formatting.
*   **path_provider:** For accessing the local file system to store user data.

## Project Structure 📁

The project follows a feature-oriented structure:

*   `lib/`: Contains all the Dart code for the application.
    *   `main.dart`: The main entry point of the application.
    *   `core/`: Implements core logic like the Command pattern and logging.
    *   `mixins/`: Contains reusable mixins, such as `DeadlineCheckMixin`.
    *   `models/`: Defines the data models for:
        *   `Tasks/`: `TaskBase`, `Task`, `RootTask`, `RotatingTask`.
        *   `gamefiy/`: `Rank`, `UserRank`, `TaskRarity`.
        *   `user.dart`: The main user model.
    *   `providers/`: Houses state management logic, primarily `UserProvider`.
    *   `screens/`: Contains the UI screens for different parts of the app (e.g., `DashboardScreen`, `TreeScreen`).
    *   `utils/`: Includes utility classes for constants, date formatting, dialogs, local storage (`StorageService`), and task-related helper functions (`TaskUtils`).
    *   `widgets/`: Contains reusable UI components like `TaskCard`, `RankIndicator`, `TaskTile`, dialogs, etc.

## Getting Started 🚀

To run this project locally:

1.  **Prerequisites:**
    *   Ensure you have the Flutter SDK installed and configured on your system.
    *   An editor like VS Code or Android Studio with Flutter plugins.
2.  **Clone the Repository:**
    ```bash
    git clone <repository-url>
    cd <project-directory>
    ```
3.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Run the Application:**
    ```bash
    flutter run
    ```
    Select a connected device or emulator when prompted.
