#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>

#define BLOCK_SIZE 4096
#define WORD_SIZE 32
#define LINE_DISPLAY_MAX 16

// Structure to define a node of the trie
typedef struct Node {
  struct Node* left;
  struct Node* right;
  struct Node* next;
  char letter;
  unsigned int count;
  unsigned int* lines;
} Node;

// Insert a word in the trie, or update its count of occurrences if it already exists
// Return the number of nodes that have been created, or -1 in case of error
int TrieInsert (Node** nodePtr, char* word, unsigned int lineNumber)
{
  // Process all the letters of the word
  Node* node = NULL;
  int nodeCreated = 0;
  while (1) {

    // Check whether this is the last character of the word
    char letter = *word++;
    if (letter == '\0') {

      // Check whether the node exists (empty string?)
      if (!node) {
        return nodeCreated;
      }

      // Take note of the line number
      node->lines = (unsigned int*) realloc (node->lines, (node->count + 1) * sizeof (unsigned int));
      if (!node->lines) {
        return -1;
      }
      node->lines [node->count++] = lineNumber;

      // Return the number of nodes that have been created
      return nodeCreated;
    }

    // Search for the letter
    while (1) {

      // Check whether the node exists
      node = *nodePtr;
      if (!node) {

        // Create a node
        node = (Node*) malloc (sizeof (Node));
        if (!node) {
          return -1;
        }
        ++nodeCreated;
        *nodePtr = node;

        // Initialize the node
        node->left = NULL;
        node->right = NULL;
        node->next = NULL;
        node->letter = letter;
        node->count = 0;
        node->lines = NULL;
        break;
      }

      // Check whether this is the correct letter
      if (letter == node->letter) {
        break;
      }
      nodePtr = letter < node->letter ? &node->left : &node->right;
    }

    // Next letter...
    nodePtr = &node->next;
  }
}

// Display all the words recorded in the trie
static char wordDisplay [WORD_SIZE];
void TrieDisplay (Node* node, unsigned int depth)
{
  // Make sure the node exists
  if (!node || depth >= sizeof (wordDisplay) - 1) {
    return;
  }

  // Go to the left
  TrieDisplay (node->left, depth);

  // Build the word
  wordDisplay [depth] = node->letter;

  // Check whether a word is completed
  if (node->count > 0) {
    wordDisplay [depth + 1] = '\0';
    printf ("\"%s\" x %u (", wordDisplay, node->count);
    unsigned int lineIndex = 0;
    while (1) {
      printf ("L%u", node->lines [lineIndex]);
      if (++lineIndex == (LINE_DISPLAY_MAX + 1) / 2 && node->count > LINE_DISPLAY_MAX) {
        printf (", ...");
        lineIndex = node->count - LINE_DISPLAY_MAX / 2;
      }
      if (lineIndex >= node->count) {
        break;
      }
      printf (", ");
    }
    puts (")");
  }

  // Go below
  TrieDisplay (node->next, depth + 1);

  // Go to the right
  TrieDisplay (node->right, depth);
}

// Destroy the trie (clean up the memory)
void TrieDestroy (Node* node)
{
  // Make sure the node exists
  if (node) {

    // Check all the child nodes
    TrieDestroy (node->left);
    TrieDestroy (node->right);
    TrieDestroy (node->next);

    // Destroy the node itself
    free (node->lines);
    free (node);
  }
}

// Read a block of text
// Return the next letter of the text, or '\0' if its end has been reached
char BlockRead (FILE* file, char* block, unsigned int blockSize)
{
  static unsigned int blockIndex = 0;
  static unsigned int blockEnd = 0;
  if (blockIndex >= blockEnd) {
    blockEnd = fread (block, 1, blockSize, file);
    if (!blockEnd) {
      return '\0';
    }
    blockIndex = 0;
  }
  return block [blockIndex++];
}

// Main
int main (int argc, char** argv)
{
  // Check the arguments
  if (argc > 2) {
    printf ("ERROR: Syntax: %s [fileName]\n", argv [0]);
    return -1;
  }

  // Attempt to open the file (or stdin if no argument)
  FILE* file = argc == 1 ? stdin : fopen (argv [1], "r");
  if (!file) {
    argc == 1 ? puts ("ERROR: Could not open the standard input.") : printf ("ERROR: Could not open the file \"%s\".\n", argv [1]);
    return -2;
  }

  // Take note of the time
  clock_t time = clock ();

  // Read the file a block after another
  char block [BLOCK_SIZE];
  char letter = '\n';
  unsigned int lineNumber = 0;
  unsigned int wordCount = 0;
  unsigned int wordCountUnique = 0;
  Node* nodeRoot = NULL;
  unsigned int nodeCount = 0;
  int errorCode = 0;

  while (1) {

    // Skip non-letter characters
    int lineNumberIncreased;
    do {
      if ((lineNumberIncreased = (letter == '\n'))) {
        ++lineNumber;
      }
    } while ((letter = BlockRead (file, block, sizeof (block))) != '\0' && !isalnum (letter));

    // End of the text?
    if (letter == '\0') {

      // Do not take the latest line feed into account if it was the very last character
      if (lineNumberIncreased) {
        --lineNumber;
      }
      break;
    }

    // Read a word
    char word [WORD_SIZE];
    unsigned int wordIndex = 0;
    do {
      if (wordIndex >= sizeof (word) - 1) {
        puts ("ERROR: Could not read a word (word too long).\n");
        errorCode = -3;
        break;
      }
      word [wordIndex++] = tolower (letter);
    } while ((letter = BlockRead (file, block, sizeof (block))) != '\0' && isalnum (letter));

    // Error?
    if (errorCode) {
      break;
    }

    // The word is completed, mark its end
    word [wordIndex] = '\0';

    // Insert this word in the trie
    int nodeCreated = TrieInsert (&nodeRoot, word, lineNumber);
    if (nodeCreated < 0) {
      puts ("ERROR: Could not create a new node.\n");
      errorCode = -4;
      break;
    }

    // Update the count of words
    ++wordCount;
    if (nodeCreated > 0) {
      nodeCount += nodeCreated;
      ++wordCountUnique;
    }

    // End of the text?
    if (letter == '\0') {
      break;
    }
  }

  // Take note of the time
  clock_t timeParse = clock () - time;

  // Close the file
  if (argc > 1) {
    fclose (file);
  }

  // Display all the words recorded in the trie
  puts ("WORDS FOUND:");
  time = clock ();
  TrieDisplay (nodeRoot, 0);
  clock_t timeDisplay = clock () - time;

  // Display a summary
  printf ("\nSTATUS: %s\n\nSUMMARY:\n  %u lines%s\n  %u words in total\n  %u different words\n  %u nodes (%.2f KB)\n  %.1f ms to parse\n  %.1f ms to display\n",
    errorCode ? "ERROR" : "OK",
    lineNumber,
    errorCode ? " parsed before the error occurred" : "",
    wordCount,
    wordCountUnique,
    nodeCount,
    (nodeCount * sizeof (Node) + wordCount * sizeof (unsigned int)) / 1024.0f,
    1000.0f * timeParse / CLOCKS_PER_SEC,
    1000.0f * timeDisplay / CLOCKS_PER_SEC);

  // Clean up the memory
  TrieDestroy (nodeRoot);

  // Return the error code
  return errorCode;
}
