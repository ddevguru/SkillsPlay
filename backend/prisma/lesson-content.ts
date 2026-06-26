import { GameType, Difficulty } from '@prisma/client';

export interface LessonPayload {
  title: string;
  gameType: GameType;
  content: string;
  configJson: Record<string, unknown>;
  testcases: Array<{ input: string; expectedOutput: string }>;
}

const GAME_NAMES: Record<GameType, string[]> = {
  [GameType.MICRO_LESSON]: ['Concept Quest', 'Brain Spark', 'Quick Learn'],
  [GameType.PUZZLE_REORDER]: ['Step Master', 'Logic Ladder', 'Order Up!'],
  [GameType.PUZZLE_DRAG_DROP]: ['Match Maker', 'Sort It Out', 'Category Clash'],
  [GameType.CODE_COMPLETION]: ['Code Quest', 'Bug Hunt', 'Syntax Sprint'],
  [GameType.TIMED_CHALLENGE]: ['Speed Code', 'Race Against Time', 'Lightning Round'],
  [GameType.SCENARIO_SIMULATION]: ['Real World Rescue', 'Dev Dilemma', 'Choose Wisely'],
};

const TOPIC_BANK: Record<string, Record<string, TopicContent>> = {
  python: {
    'Variables & Types': {
      lesson: {
        slides: [
          { title: 'Variables = Labeled Boxes', body: 'In Python, variables store values. x = 42 means the box labeled x holds 42.' },
          { title: 'Dynamic Typing', body: 'Python figures out the type automatically. x = "hello" makes x a string — no type keyword needed!' },
          { title: 'Common Types', body: 'int (42), float (3.14), str ("hi"), bool (True/False), list ([1,2]), dict ({"a": 1})' },
        ],
        quiz: {
          question: 'What type is the value stored in: age = 25?',
          options: ['int', 'str', 'float', 'bool'],
          expectedAnswer: 'int',
        },
      },
      reorder: {
        items: ['Pick a meaningful name', 'Assign a value with =', 'Use the variable in code', 'Check type with type()'],
        expectedAnswer: ['Pick a meaningful name', 'Assign a value with =', 'Use the variable in code', 'Check type with type()'],
      },
      dragDrop: {
        items: ['42', '"hello"', '3.14', 'True'],
        zones: ['int', 'str', 'float', 'bool'],
        expectedAnswer: { int: '42', str: '"hello"', float: '3.14', bool: 'True' },
      },
      scenario: {
        steps: [
          { prompt: 'Your code crashes: TypeError: can only concatenate str (not "int") to str. First move?', options: ['Convert int to str with str()', 'Delete the line', 'Restart computer'] },
          { prompt: 'You need user age as a number for math. input() returns a string. What next?', options: ['int(input())', 'str(input())', 'print(input())'] },
        ],
        expectedAnswer: ['Convert int to str with str()', 'int(input())'],
      },
      code: {
        language: 'python',
        starterCode: 'def greet(name):\n    # Return "Hello, <name>!"\n    pass\n',
        expectedAnswer: 'pass',
      },
    },
    Arrays: {
      lesson: {
        slides: [
          { title: 'Lists Are Flexible', body: 'Python lists hold multiple items: nums = [1, 2, 3]. They can grow and shrink!' },
          { title: 'Indexing', body: 'First item is index 0. nums[0] → 1. Negative index counts from end: nums[-1] → last item.' },
        ],
        quiz: {
          question: 'What does [1, 2, 3][-1] return?',
          options: ['3', '1', '-1', 'Error'],
          expectedAnswer: '3',
        },
      },
      reorder: {
        items: ['Create empty list', 'Append items', 'Access by index', 'Iterate with for loop'],
        expectedAnswer: ['Create empty list', 'Append items', 'Access by index', 'Iterate with for loop'],
      },
      dragDrop: {
        items: ['append()', 'pop()', 'len()', 'sort()'],
        zones: ['Add to end', 'Remove last', 'Get count', 'Order items'],
        expectedAnswer: { 'Add to end': 'append()', 'Remove last': 'pop()', 'Get count': 'len()', 'Order items': 'sort()' },
      },
      scenario: {
        steps: [
          { prompt: 'You need unique items from a list with duplicates. Best approach?', options: ['set(my_list)', 'my_list.sort()', 'my_list.reverse()'] },
          { prompt: 'List is empty but you need the last element safely.', options: ['Check len() first', 'Always use [-1]', 'Use pop(0)'] },
        ],
        expectedAnswer: ['set(my_list)', 'Check len() first'],
      },
      code: {
        language: 'python',
        starterCode: 'def solve(nums):\n    # Return sum of all numbers\n    pass\n',
        expectedAnswer: 'pass',
      },
    },
  },
  dsa: {
    Arrays: {
      lesson: {
        slides: [
          { title: 'Arrays = Contiguous Memory', body: 'Elements sit next to each other. Access any index in O(1) time — super fast reads!' },
          { title: 'Trade-off', body: 'Inserting in the middle costs O(n) — elements must shift. Great for lookups, less for frequent inserts.' },
        ],
        quiz: {
          question: 'Time complexity to access arr[i] by index?',
          options: ['O(1)', 'O(n)', 'O(log n)', 'O(n²)'],
          expectedAnswer: 'O(1)',
        },
      },
      reorder: {
        items: ['Define problem & constraints', 'Choose array vs other structure', 'Write brute force', 'Optimize with two pointers / hash map'],
        expectedAnswer: ['Define problem & constraints', 'Choose array vs other structure', 'Write brute force', 'Optimize with two pointers / hash map'],
      },
      dragDrop: {
        items: ['Two Sum', 'Binary Search', 'Kadane\'s Algorithm', 'Merge Intervals'],
        zones: ['Hash Map lookup', 'Sorted array', 'Max subarray sum', 'Overlapping ranges'],
        expectedAnswer: { 'Hash Map lookup': 'Two Sum', 'Sorted array': 'Binary Search', 'Max subarray sum': "Kadane's Algorithm", 'Overlapping ranges': 'Merge Intervals' },
      },
      scenario: {
        steps: [
          { prompt: 'You need to find if a target exists in an UNSORTED array of 1M items.', options: ['Hash set O(1) lookup', 'Binary search', 'Sort then linear scan'] },
          { prompt: 'Memory is tight. Array of 10M ints uses ~40MB. Alternative?', options: ['Stream/process in chunks', 'Use double size array', 'Store as strings'] },
        ],
        expectedAnswer: ['Hash set O(1) lookup', 'Stream/process in chunks'],
      },
      code: {
        language: 'python',
        starterCode: 'def solve(nums):\n    # Return maximum element\n    pass\n',
        expectedAnswer: 'pass',
      },
    },
    'Linked Lists': {
      lesson: {
        slides: [
          { title: 'Nodes & Pointers', body: 'Each node holds data + a pointer to the next node. No random access — traverse from head.' },
          { title: 'Why Use Them?', body: 'O(1) insert/delete at known position. Perfect for queues, LRU caches, and undo stacks.' },
        ],
        quiz: {
          question: 'Accessing the 5th element in a linked list is?',
          options: ['O(n)', 'O(1)', 'O(log n)', 'O(1) with cache'],
          expectedAnswer: 'O(n)',
        },
      },
      reorder: {
        items: ['Create node with value', 'Point next pointer', 'Update head/tail', 'Detect cycle with slow/fast pointers'],
        expectedAnswer: ['Create node with value', 'Point next pointer', 'Update head/tail', 'Detect cycle with slow/fast pointers'],
      },
      dragDrop: {
        items: ['Singly linked', 'Doubly linked', 'Circular', 'Skip list'],
        zones: ['One direction only', 'Forward + backward', 'Last points to first', 'Multi-level fast search'],
        expectedAnswer: { 'One direction only': 'Singly linked', 'Forward + backward': 'Doubly linked', 'Last points to first': 'Circular', 'Multi-level fast search': 'Skip list' },
      },
      scenario: {
        steps: [
          { prompt: 'Interview asks: detect cycle in linked list. Classic technique?', options: ['Floyd tortoise & hare', 'Sort the list', 'Convert to array'] },
          { prompt: 'Need O(1) delete at tail. Which list type helps?', options: ['Doubly linked with tail ptr', 'Singly linked only', 'Array'] },
        ],
        expectedAnswer: ['Floyd tortoise & hare', 'Doubly linked with tail ptr'],
      },
      code: {
        language: 'python',
        starterCode: 'def solve(arr):\n    # Reverse the array (practice pointer logic)\n    pass\n',
        expectedAnswer: 'pass',
      },
    },
  },
  javascript: {
    Promises: {
      lesson: {
        slides: [
          { title: 'Promise = Future Value', body: 'A Promise represents work that finishes later: pending → fulfilled or rejected.' },
          { title: 'Chaining', body: '.then() handles success, .catch() handles errors. Return a value to chain another .then().' },
        ],
        quiz: {
          question: 'Which method handles a rejected Promise?',
          options: ['.catch()', '.then()', '.finally()', '.map()'],
          expectedAnswer: '.catch()',
        },
      },
      reorder: {
        items: ['Create Promise', 'Executor runs async work', 'Call resolve/reject', 'Consumer uses .then/.catch'],
        expectedAnswer: ['Create Promise', 'Executor runs async work', 'Call resolve/reject', 'Consumer uses .then/.catch'],
      },
      dragDrop: {
        items: ['pending', 'fulfilled', 'rejected', 'settled'],
        zones: ['Initial state', 'Success', 'Failure', 'Done (either outcome)'],
        expectedAnswer: { 'Initial state': 'pending', Success: 'fulfilled', Failure: 'rejected', 'Done (either outcome)': 'settled' },
      },
      scenario: {
        steps: [
          { prompt: 'API call fails. User sees blank screen. Best fix?', options: ['Add .catch() with error UI', 'Ignore the error', 'Use sync fetch'] },
          { prompt: 'Three API calls must run in sequence. Tool?', options: ['async/await chain', 'Promise.all for all parallel', 'setTimeout'] },
        ],
        expectedAnswer: ['Add .catch() with error UI', 'async/await chain'],
      },
      code: {
        language: 'javascript',
        starterCode: 'function solve(arr) {\n  // Return sum of array\n}\n',
        expectedAnswer: 'pass',
      },
    },
  },
};

interface TopicContent {
  lesson: { slides: Array<{ title: string; body: string }>; quiz: { question: string; options: string[]; expectedAnswer: string } };
  reorder: { items: string[]; expectedAnswer: string[] };
  dragDrop: { items: string[]; zones: string[]; expectedAnswer: Record<string, string> };
  scenario: { steps: Array<{ prompt: string; options: string[] }>; expectedAnswer: string[] };
  code: { language: string; starterCode: string; expectedAnswer: string };
}

function genericContent(track: string, topic: string, idx: number): LessonPayload {
  const patterns = idx % 6;
  const lang = ['java', 'cpp'].includes(track) ? 'java' : track === 'javascript' ? 'javascript' : 'python';

  if (patterns === 2 || patterns === 5) {
    const starterCode =
      lang === 'java'
        ? 'public String solve(int[] arr) {\n    // Your logic here\n    return "";\n}'
        : lang === 'javascript'
          ? 'function solve(arr) {\n  // Your logic here\n}\n'
          : `def solve(data):\n    """Solve a ${topic} challenge in ${track}."""\n    pass\n`;
    return {
      title: `${GAME_NAMES[patterns === 5 ? GameType.TIMED_CHALLENGE : GameType.CODE_COMPLETION][idx % 3]}: ${topic}`,
      gameType: patterns === 5 ? GameType.TIMED_CHALLENGE : GameType.CODE_COMPLETION,
      content: `Write code to solve this ${topic} problem. Think before you type!`,
      configJson: { language: lang, starterCode, timeLimitSeconds: patterns === 5 ? 90 : 300, expectedAnswer: 'pass' },
      testcases: [
        { input: '[1,2,3]', expectedOutput: '6' },
        { input: '[0]', expectedOutput: '0' },
      ],
    };
  }
  if (patterns === 1) {
    const items = ['Understand the problem', 'Plan your approach', 'Implement step by step', 'Test edge cases', 'Refactor & optimize'];
    return {
      title: `${GAME_NAMES[GameType.PUZZLE_REORDER][idx % 3]}: ${topic}`,
      gameType: GameType.PUZZLE_REORDER,
      content: `Put the problem-solving steps in the right order for ${topic}.`,
      configJson: { items, expectedAnswer: items, shuffleOnLoad: true },
      testcases: [],
    };
  }
  if (patterns === 3) {
    const items = [`${topic} concept A`, `${topic} concept B`, `${topic} tool C`];
    const zones = ['Definition', 'Use case', 'Best practice'];
    return {
      title: `${GAME_NAMES[GameType.PUZZLE_DRAG_DROP][idx % 3]}: ${topic}`,
      gameType: GameType.PUZZLE_DRAG_DROP,
      content: `Match each item to its correct category for ${topic}.`,
      configJson: {
        items,
        zones,
        expectedAnswer: { Definition: items[0], 'Use case': items[1], 'Best practice': items[2] },
      },
      testcases: [],
    };
  }
  if (patterns === 4) {
    return {
      title: `${GAME_NAMES[GameType.SCENARIO_SIMULATION][idx % 3]}: ${topic}`,
      gameType: GameType.SCENARIO_SIMULATION,
      content: `You're in a real ${track} project facing a ${topic} challenge. Choose wisely!`,
      configJson: {
        steps: [
          { prompt: `Production bug related to ${topic}. First step?`, options: ['Reproduce & read logs', 'Deploy a hotfix blindly', 'Blame the intern'] },
          { prompt: 'How do you prevent this again?', options: ['Add tests & code review', 'Hope it does not happen', 'Disable the feature'] },
        ],
        expectedAnswer: ['Reproduce & read logs', 'Add tests & code review'],
      },
      testcases: [],
    };
  }
  return {
    title: `${GAME_NAMES[GameType.MICRO_LESSON][idx % 3]}: ${topic}`,
    gameType: GameType.MICRO_LESSON,
    content: `Interactive mini-lesson on ${topic} in ${track}.`,
    configJson: {
      slides: [
        { title: `${topic} Essentials`, body: `Core ideas every ${track} developer should know about ${topic}.` },
        { title: 'Pro Tip', body: 'Practice beats passive reading. Apply what you learn in the next challenge!' },
      ],
      quiz: {
        question: `Ready to master ${topic}?`,
        options: ['Let\'s go!', 'Maybe later'],
        expectedAnswer: 'Let\'s go!',
      },
      expectedAnswer: 'Let\'s go!',
    },
    testcases: [],
  };
}

export function buildLesson(track: string, topic: string, idx: number, difficulty: Difficulty): LessonPayload {
  const bank = TOPIC_BANK[track]?.[topic];
  const patterns = idx % 6;

  if (bank) {
    if (patterns === 0) {
      const b = bank.lesson;
      return {
        title: `${GAME_NAMES[GameType.MICRO_LESSON][idx % 3]}: ${topic}`,
        gameType: GameType.MICRO_LESSON,
        content: `Learn ${topic} through bite-sized slides, then prove it in the quiz!`,
        configJson: { slides: b.slides, quiz: b.quiz, expectedAnswer: b.quiz.expectedAnswer },
        testcases: [],
      };
    }
    if (patterns === 1) {
      const b = bank.reorder;
      return {
        title: `${GAME_NAMES[GameType.PUZZLE_REORDER][idx % 3]}: ${topic}`,
        gameType: GameType.PUZZLE_REORDER,
        content: `Drag the steps into the correct order — this is how pros think about ${topic}.`,
        configJson: { items: b.items, expectedAnswer: b.expectedAnswer, shuffleOnLoad: true },
        testcases: [],
      };
    }
    if (patterns === 3) {
      const b = bank.dragDrop;
      return {
        title: `${GAME_NAMES[GameType.PUZZLE_DRAG_DROP][idx % 3]}: ${topic}`,
        gameType: GameType.PUZZLE_DRAG_DROP,
        content: `Match concepts to categories. Getting this right means you truly understand ${topic}!`,
        configJson: { items: b.items, zones: b.zones, expectedAnswer: b.expectedAnswer },
        testcases: [],
      };
    }
    if (patterns === 4) {
      const b = bank.scenario;
      return {
        title: `${GAME_NAMES[GameType.SCENARIO_SIMULATION][idx % 3]}: ${topic}`,
        gameType: GameType.SCENARIO_SIMULATION,
        content: `Real-world ${topic} scenario — your choices matter!`,
        configJson: { steps: b.steps, expectedAnswer: b.expectedAnswer },
        testcases: [],
      };
    }
    if (patterns === 2 || patterns === 5) {
      const b = bank.code;
      const lang = b.language;
      const testcases =
        lang === 'javascript'
          ? [{ input: '[1,2,3]', expectedOutput: '6' }]
          : [
              { input: '[1,2,3]', expectedOutput: '6' },
              { input: '[0]', expectedOutput: '0' },
            ];
      return {
        title: `${GAME_NAMES[patterns === 5 ? GameType.TIMED_CHALLENGE : GameType.CODE_COMPLETION][idx % 3]}: ${topic}`,
        gameType: patterns === 5 ? GameType.TIMED_CHALLENGE : GameType.CODE_COMPLETION,
        content: patterns === 5
          ? `⚡ Speed round! Solve this ${topic} challenge before time runs out.`
          : `Complete the code to demonstrate your ${topic} skills.`,
        configJson: {
          language: lang,
          starterCode: b.starterCode,
          timeLimitSeconds: patterns === 5 ? 90 : 300,
          expectedAnswer: b.expectedAnswer,
        },
        testcases,
      };
    }
  }

  return genericContent(track, topic, idx);
}
