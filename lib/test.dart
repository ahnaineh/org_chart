
// class Person {
//   final String id;
//   final String name;
//   final String? fatherId;
//   final String? motherId;
//   final List<String> spouseIds;

//   Person({
//     required this.id,
//     required this.name,
//     this.fatherId,
//     this.motherId,
//     this.spouseIds = const [],
//   });
// }

// // Sample family data
// List<Person> familyData = [
//   Person(id: "1", name: "John", fatherId: null, motherId: null, spouseIds: ["2"]),
//   Person(id: "2", name: "Jane", fatherId: null, motherId: null, spouseIds: ["1"]),
//   Person(id: "3", name: "Alice", fatherId: "1", motherId: "2", spouseIds: ["4"]),
//   Person(id: "4", name: "Bob", fatherId: null, motherId: null, spouseIds: ["3"]),
//   Person(id: "5", name: "Charlie", fatherId: "3", motherId: "4"),
// ];

// // John --- Jane
// //       | 
// //     Alice --- Bob
// //            |
// //         Charlie

// // Function to get children dynamically
// List<Person> getChildren(String parentId, List<Person> allPeople) {
//   return allPeople.where((p) => p.fatherId == parentId || p.motherId == parentId).toList();
// }


// // Step 2: Compute Generation Levels
// Map<String, int> computeLevels(String egoId, List<Person> people) {
//   Map<String, int> levels = {};
//   void assignLevel(String id, int level) {
//     if (levels.containsKey(id)) return;
//     levels[id] = level;
//     Person? person = people.firstWhere((p) => p.id == id, orElse: () => Person(id: "", name: ""));
//     if (person.id.isNotEmpty) {
//       if (person.fatherId != null) assignLevel(person.fatherId!, level - 1);
//       if (person.motherId != null) assignLevel(person.motherId!, level - 1);
//       for (var spouseId in person.spouseIds) {
//         assignLevel(spouseId, level);
//       }
//       for (var child in getChildren(id, people)) {
//         assignLevel(child.id, level + 1);
//       }
//     }
//   }
//   assignLevel(egoId, 0);
//   return levels;
// }

// // Step 3: Assign X Coordinates for Layout
// Map<String, double> computeXPositions(List<Person> people, Map<String, int> levels) {
//   Map<int, List<String>> groupedByLevel = {};
//   Map<String, double> xPositions = {};
  
//   // Group persons by generation level
//   levels.forEach((id, level) {
//     groupedByLevel.putIfAbsent(level, () => []).add(id);
//   });

//   // Assign X positions based on order within each level
//   groupedByLevel.forEach((level, ids) {
//     double x = 0;
//     for (var id in ids) {
//       xPositions[id] = x;
//       x += 1.5; // Space between nodes
//     }
//   });

//   return xPositions;
// }

// void main() {
//   // Example usage
//   String targetId = "3";
//   Map<String, int> levels = computeLevels(targetId, familyData);
//   Map<String, double> xPositions = computeXPositions(familyData, levels);
  
//   print("Node positions:");
//   xPositions.forEach((id, x) {
//     print("${familyData.firstWhere((p) => p.id == id).name}: X = $x, Level = ${levels[id]}");
//   });
// }


//                      ┌───────────────┐     ┌───────────────┐
//                      │  Robert Smith  │───▶│  Mary Smith    │
//                      │ (1920-1990)    │    │ (1925-1995)    │
//                      └───────────────┘     └───────────────┘
//                                │
//          ┌───────────────┬───────────────┐
//          │               │               │
// ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
// │  John Smith   │ │  Thomas Smith │ │  (No Children)│
// │ (1950- )      │ │ (1955- )      │ │  (Barbara J.) │
// └───────────────┘ └───────────────┘ └───────────────┘
//          │                 │
//          │        ┌────────┴─────────┐
//          │        │                  │
//          │  ┌───────────────┐  ┌───────────────┐
//          │  │  Patricia     │  │  Jennifer     │
//          │  │ (1958- )      │  │ (1960- )      │
//          │  └───────────────┘  └───────────────┘
//          │        │                  │
//          │  ┌───────────────┐  ┌───────────────┐
//          │  │  Jessica      │  │  Matthew      │
//          │  │ (1978- )      │  │ (1988- )      │
//          │  └───────────────┘  │  Olivia       │
//          │                     │ (1988- )      │
//          │                     └───────────────┘
// ┌───────────────┐
// │  Sarah Smith  │
// │ (1952- )      │
// └───────────────┘
//          │
//  ┌───────────────┬───────────────┬───────────────┬───────────────┐
//  │  Michael      │  David        │  Daniel       │  Emily        │
//  │ (1975- )      │ (1980- )      │ (1980- )      │ (1985- )      │
//  └───────────────┴───────────────┴───────────────┴───────────────┘
//          │
//  ┌───────────────┐
//  │  Amanda Smith │
//  │ (1978- )      │
//  └───────────────┘
//          │
//  ┌───────────────┬───────────────┐
//  │  Sophia       │  William      │
//  │ (2005- )      │ (2008- )      │
//  └───────────────┴───────────────┘
