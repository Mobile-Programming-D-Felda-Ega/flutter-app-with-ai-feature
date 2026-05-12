/// On-device keyword extraction engine for academic text.
///
/// This service processes OCR text locally on the device:
/// 1. Tokenizes text into words
/// 2. Removes common stop words
/// 3. Matches against an academic topic dictionary (100+ terms)
/// 4. Supports multi-word terms via n-gram matching
/// 5. Scores topics by frequency and relevance
///
/// No cloud API is used — everything runs in Dart on the device.
class KeywordExtractor {
  KeywordExtractor._();
  static final instance = KeywordExtractor._();

  /// Extract keywords and topic scores from raw OCR text.
  ///
  /// Returns a record of (keywords, topicScores).
  ({List<String> keywords, Map<String, double> topicScores}) extract(
    String rawText,
  ) {
    if (rawText.trim().isEmpty) {
      return (keywords: <String>[], topicScores: <String, double>{});
    }

    final normalizedText = rawText.toLowerCase();
    final detectedKeywords = <String>{};
    final topicHits = <String, int>{};

    // --- Phase 1: Multi-word term matching (n-grams) ---
    for (final entry in _topicDictionary.entries) {
      final topic = entry.key;
      final terms = entry.value;

      for (final term in terms) {
        if (normalizedText.contains(term.toLowerCase())) {
          detectedKeywords.add(term);
          topicHits[topic] = (topicHits[topic] ?? 0) + 1;
        }
      }
    }

    // --- Phase 2: Single-word token matching ---
    final tokens = _tokenize(normalizedText);
    for (final token in tokens) {
      if (_singleWordTerms.containsKey(token)) {
        final topic = _singleWordTerms[token]!;
        // Only add if not already captured by n-gram
        if (detectedKeywords.add(token)) {
          topicHits[topic] = (topicHits[topic] ?? 0) + 1;
        }
      }
    }

    // --- Phase 3: Score normalization (0.0 - 1.0) ---
    final maxHits = topicHits.values.fold<int>(0, (a, b) => a > b ? a : b);
    final topicScores = <String, double>{};
    if (maxHits > 0) {
      for (final entry in topicHits.entries) {
        // Normalize score: hits/maxHits, minimum 0.3 for any match
        topicScores[entry.key] = 0.3 + 0.7 * (entry.value / maxHits);
      }
    }

    // Sort keywords alphabetically for consistent display
    final sortedKeywords = detectedKeywords.toList()..sort();

    return (keywords: sortedKeywords, topicScores: topicScores);
  }

  /// Tokenize text into individual words, removing stop words and short tokens.
  List<String> _tokenize(String text) {
    return text
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Academic Topic Dictionary
  // ---------------------------------------------------------------------------
  // Maps topic categories to their related terms (multi-word and phrases).
  // This acts as a lightweight "knowledge base" for the on-device NLP.

  static const Map<String, List<String>> _topicDictionary = {
    'Machine Learning': [
      'machine learning',
      'supervised learning',
      'unsupervised learning',
      'reinforcement learning',
      'neural network',
      'deep learning',
      'decision tree',
      'random forest',
      'gradient descent',
      'loss function',
      'training data',
      'test data',
      'overfitting',
      'underfitting',
      'cross validation',
      'feature extraction',
      'classification',
      'regression',
      'clustering',
    ],
    'Deep Learning': [
      'convolutional neural network',
      'recurrent neural network',
      'backpropagation',
      'activation function',
      'batch normalization',
      'dropout',
      'transfer learning',
      'generative adversarial',
      'autoencoder',
      'attention mechanism',
      'transformer',
      'epoch',
      'layer',
    ],
    'Artificial Intelligence': [
      'artificial intelligence',
      'natural language processing',
      'computer vision',
      'robotics',
      'expert system',
      'knowledge representation',
      'search algorithm',
      'heuristic',
      'intelligent agent',
    ],
    'Pemrograman Mobile': [
      'flutter',
      'react native',
      'mobile development',
      'android studio',
      'user interface',
      'widget',
      'state management',
      'navigation',
      'responsive design',
      'mobile app',
    ],
    'Basis Data': [
      'database',
      'basis data',
      'relational database',
      'entity relationship',
      'normalisasi',
      'normalization',
      'primary key',
      'foreign key',
      'stored procedure',
      'data warehouse',
      'indexing',
    ],
    'Algoritma dan Pemrograman': [
      'dynamic programming',
      'divide and conquer',
      'greedy algorithm',
      'sorting algorithm',
      'binary search',
      'linked list',
      'stack',
      'queue',
      'tree traversal',
      'graph traversal',
      'time complexity',
      'space complexity',
      'big o notation',
      'recursion',
      'iteration',
    ],
    'Struktur Data': [
      'struktur data',
      'data structure',
      'binary tree',
      'hash table',
      'hash map',
      'priority queue',
      'balanced tree',
      'red black tree',
      'adjacency list',
      'adjacency matrix',
    ],
    'Jaringan Komputer': [
      'jaringan komputer',
      'computer network',
      'tcp ip',
      'http',
      'dns',
      'firewall',
      'routing',
      'switching',
      'osi model',
      'subnet',
      'ip address',
      'bandwidth',
      'latency',
      'protocol',
    ],
    'Sistem Operasi': [
      'sistem operasi',
      'operating system',
      'process scheduling',
      'memory management',
      'virtual memory',
      'file system',
      'deadlock',
      'semaphore',
      'mutex',
      'thread',
      'kernel',
      'paging',
    ],
    'Pemrograman Web': [
      'web development',
      'html',
      'css',
      'javascript',
      'typescript',
      'react',
      'angular',
      'vue',
      'node js',
      'rest api',
      'frontend',
      'backend',
      'full stack',
    ],
    'Matematika': [
      'kalkulus',
      'calculus',
      'linear algebra',
      'aljabar linear',
      'probabilitas',
      'probability',
      'statistika',
      'statistics',
      'matriks',
      'matrix',
      'integral',
      'diferensial',
      'derivative',
      'vektor',
      'vector',
    ],
    'Keamanan Siber': [
      'cyber security',
      'keamanan siber',
      'encryption',
      'enkripsi',
      'cryptography',
      'kriptografi',
      'authentication',
      'authorization',
      'vulnerability',
      'penetration testing',
      'malware',
    ],
    'Cloud Computing': [
      'cloud computing',
      'aws',
      'google cloud',
      'azure',
      'docker',
      'kubernetes',
      'microservices',
      'serverless',
      'devops',
      'ci cd',
      'deployment',
    ],
    'Data Science': [
      'data science',
      'data analysis',
      'data visualization',
      'pandas',
      'numpy',
      'matplotlib',
      'jupyter',
      'big data',
      'data mining',
      'data preprocessing',
    ],
  };

  // Single-word terms mapped to their topic.
  // Built from shorter/unique terms that are unambiguous.
  static final Map<String, String> _singleWordTerms = {
    // Machine Learning / Deep Learning
    'tensorflow': 'Machine Learning',
    'pytorch': 'Machine Learning',
    'keras': 'Deep Learning',
    'sklearn': 'Machine Learning',
    'scikit': 'Machine Learning',
    'cnn': 'Deep Learning',
    'rnn': 'Deep Learning',
    'lstm': 'Deep Learning',
    'gan': 'Deep Learning',
    'perceptron': 'Deep Learning',
    'softmax': 'Deep Learning',
    'sigmoid': 'Deep Learning',
    'relu': 'Deep Learning',
    'convolution': 'Deep Learning',
    'pooling': 'Deep Learning',
    'embedding': 'Deep Learning',
    'neuron': 'Deep Learning',

    // AI
    'nlp': 'Artificial Intelligence',
    'chatbot': 'Artificial Intelligence',
    'inference': 'Artificial Intelligence',

    // Programming
    'dart': 'Pemrograman Mobile',
    'kotlin': 'Pemrograman Mobile',
    'swift': 'Pemrograman Mobile',
    'android': 'Pemrograman Mobile',
    'ios': 'Pemrograman Mobile',
    'firebase': 'Pemrograman Mobile',

    // Database
    'sql': 'Basis Data',
    'mysql': 'Basis Data',
    'postgresql': 'Basis Data',
    'mongodb': 'Basis Data',
    'nosql': 'Basis Data',
    'query': 'Basis Data',
    'erd': 'Basis Data',
    'ddl': 'Basis Data',
    'dml': 'Basis Data',

    // Data Structure / Algorithm
    'array': 'Struktur Data',
    'heap': 'Struktur Data',
    'trie': 'Struktur Data',
    'graph': 'Struktur Data',
    'sorting': 'Algoritma dan Pemrograman',
    'mergesort': 'Algoritma dan Pemrograman',
    'quicksort': 'Algoritma dan Pemrograman',
    'bubblesort': 'Algoritma dan Pemrograman',
    'algorithm': 'Algoritma dan Pemrograman',
    'algoritma': 'Algoritma dan Pemrograman',

    // Networking
    'tcp': 'Jaringan Komputer',
    'udp': 'Jaringan Komputer',
    'ethernet': 'Jaringan Komputer',
    'wifi': 'Jaringan Komputer',
    'vpn': 'Jaringan Komputer',
    'dhcp': 'Jaringan Komputer',

    // OS
    'linux': 'Sistem Operasi',
    'windows': 'Sistem Operasi',
    'unix': 'Sistem Operasi',
    'process': 'Sistem Operasi',
    'scheduling': 'Sistem Operasi',

    // Web
    'api': 'Pemrograman Web',
    'php': 'Pemrograman Web',
    'laravel': 'Pemrograman Web',
    'django': 'Pemrograman Web',
    'express': 'Pemrograman Web',

    // Math
    'determinan': 'Matematika',
    'eigenvalue': 'Matematika',
    'turunan': 'Matematika',
    'limit': 'Matematika',

    // Data Science
    'dataset': 'Data Science',
    'kaggle': 'Data Science',
    'visualization': 'Data Science',
    'correlation': 'Data Science',
    'histogram': 'Data Science',

    // Python (general)
    'python': 'Machine Learning',
  };

  // Common stop words to filter out during tokenization.
  static const Set<String> _stopWords = {
    'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can',
    'had', 'her', 'was', 'one', 'our', 'out', 'has', 'have', 'been',
    'will', 'with', 'this', 'that', 'from', 'they', 'were',
    'said', 'each', 'which', 'their', 'about', 'would', 'make',
    'like', 'into', 'could', 'time', 'very', 'when', 'come', 'made',
    'find', 'back', 'only', 'just', 'than', 'then', 'them', 'same',
    'some', 'what', 'also', 'other', 'after', 'know', 'such',
    // Indonesian stop words
    'dan', 'yang', 'ini', 'itu', 'dari', 'untuk', 'pada', 'dengan',
    'adalah', 'dalam', 'akan', 'tidak', 'atau', 'juga', 'sudah',
    'bisa', 'ada', 'oleh', 'karena', 'secara', 'lebih', 'serta',
    'antara', 'setiap', 'harus', 'dapat', 'namun', 'maka', 'seperti',
    'ke', 'di', 'se', 'ber', 'me', 'per', 'ter', 'pen',
    'yaitu', 'saat', 'kita', 'kami', 'mereka', 'anda', 'saya',
  };
}
