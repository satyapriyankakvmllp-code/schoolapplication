# Classes module - folder guide

    classes/
      domain/          one model per file (ClassModel, SectionModel, ...)
      application/     one controller (Riverpod provider) per entity
      data/
        classes_repository.dart      the contract (ClassesRepository) + shared
                                     load/save code + MockClassesRepository
        repositories/                one file per entity: class, section, subject,
                                     curriculum, daily_lesson, timetable,
                                     classroom, teacher_work, teacher_assignment
      presentation/
        classes_hub_screen.dart      entry point; chooses the screen by role
        admin/                       screens only the Admin uses
        teacher/                     screens only the Teacher uses
        student/                     screens only the Student uses
        widgets/                     small pieces shared by every role
                                     (SearchableIdDropdown lives in classes_ui.dart)

Rules of thumb
- A screen that only one role sees goes in that role folder.
- A widget used by more than one role goes in presentation/widgets/.
- To add a new entity: add a model in domain/, a controller in application/,
  a file in data/repositories/ (and add it to the part/with lists in
  classes_repository.dart), then screens in each role folder that needs it.
- The files in data/repositories/ are Dart "part" files: together with
  classes_repository.dart they form ONE class (MockClassesRepository). The rest of
  the app only ever sees ClassesRepository, so it can later be swapped for a
  SQLite or API version without touching any screen.
