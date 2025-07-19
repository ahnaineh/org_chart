/// Constants for QuadTree spatial indexing
class QuadTreeConstants {
  // Prevent instantiation
  QuadTreeConstants._();

  // ===== Tree Structure Configuration =====
  
  /// Maximum number of nodes a QuadTree node can contain before subdivision
  static const int maxNodesPerQuadrant = 10;
  
  /// Maximum depth of the QuadTree to prevent infinite recursion
  static const int maxDepth = 8;
  
  /// Minimum size for a quadrant to be subdivided (prevents micro-quadrants)
  static const double minQuadrantSize = 32.0;
  
  // ===== Search and Query Configuration =====
  
  /// Default search radius multiplier for spatial queries
  static const double defaultSearchRadiusMultiplier = 1.5;
  
  /// Maximum number of candidates to return from spatial queries
  static const int maxQueryResults = 100;
  
  /// Padding added to bounds during QuadTree construction
  static const double boundsPadding = 50.0;
  
  // ===== Performance Optimization =====
  
  /// Initial capacity for result collections to reduce allocations
  static const int initialResultCapacity = 16;
  
  /// Threshold for switching from QuadTree to linear search (small datasets)
  static const int linearSearchThreshold = 50;
  
  /// Cache size for frequently accessed quadrants
  static const int quadrantCacheSize = 32;
}