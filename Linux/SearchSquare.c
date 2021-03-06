// This program creates an array of (size x size) elements in which it randomly
// puts blocks. It then searches for the largest square of blocks in this array.
// You may compile this program with:
//
//     gcc SearchSquare.c -o SearchSquare

// Include header files of various C libraries used by this program.
#include <stdio.h>  // printf(), putchar(), puts()
#include <stdlib.h> // srand(), rand(), malloc(), free(), atoi()
#include <stdint.h> // uint8_t, uint16_t
#include <time.h>   // time()

// Define a basic Error type, for our functions to express whether everything
// went good or not.
typedef enum {
    Success = 0,
    Failure,
} Error;

// Define the Array structure type, to hold both the actual array of blocks and
// the size of the array.
typedef struct {
    uint8_t* blocks;
    uint8_t size;
} Array;

// Define the Cell structure type, in which the SearchArray() function will
// store information about each cell.
typedef struct {
    uint8_t squareSize;
    uint8_t rowLength;
    uint8_t columnHeight;
} Cell;

// Define the Square structure type, to record results of SearchArray().
typedef struct {
    uint8_t size;
    uint8_t bottomRightX;
    uint8_t bottomRightY;
} Square;

// Create the array of blocks.
Error CreateArray(Array* array, uint8_t percentageBlock) {
    Error error = Failure;

    // Make sure we do have an array structure.
    if (array != NULL) {

        // Allocate enough memory to store all the blocks of the array.
        uint16_t xy = array->size * array->size;
        uint8_t* blocks = malloc(xy);
        if (blocks != NULL) {

            // Define the blocks.
            while (xy > 0) {
                blocks[--xy] = (rand() % 100) < percentageBlock ? 1 : 0;
            }

            // All good!
            array->blocks = blocks;
            error = Success;
        }
    }

    // Done.
    return error;
}

// Destroy the array of blocks.
Error DestroyArray(Array* array) {
    Error error = Failure;

    // Make sure we do have an array structure.
    if (array != NULL) {

        // Make sure we do have blocks.
        if (array->blocks != NULL) {

            // Free the allocated memory and reset everything.
            free(array->blocks);
            array->blocks = NULL;
            array->size = 0;
            error = Success;
        }
    }

    // Done.
    return error;
}

// Display the array of blocks.
Error DisplayArray(Array* array) {
    Error error = Failure;

    // Make sure we do have an array structure.
    if (array != NULL) {

        // Make sure we do have blocks.
        if (array->blocks != NULL) {

            // Display the header rows (X-coordinates).
            if (array->size > 10) {
                printf("    ");
                for (uint16_t x = 0; x < array->size; x += 10) {
                    printf("%-2d                  ", x / 10);
                }
                putchar('\n');
            }
            printf("    ");
            for (uint8_t x = 0; x < array->size; ++x) {
                printf("%d ", x % 10);
            }
            putchar('\n');

            // Display all the rows.
            uint8_t* block = &array->blocks[0];
            for (uint8_t y = 0; y < array->size; ++y) {

                // Display the row heading (Y-coordinates).
                printf("%3d ", y);

                // Display all the blocks in that row.
                for (uint8_t x = 0; x < array->size; ++x) {

                    // Display the block.
                    printf("%c ", *block ? 'X' : '.');

                    // Next block...
                    ++block;
                }
                putchar('\n');
            }

            // All good!
            error = Success;
        }
    }

    // Done.
    return error;
}

// Search for the largest square of blocks in the array.
Error SearchArray(Array* array, Square* square) {
    Error error = Failure;

    // Make sure we do have an array structure, blocks, and a square structure.
    if (array != NULL && array->blocks != NULL && square != NULL) {

        // Allocate enough memory to store all the needed cells. As a matter of
        // fact, we only need to record (1 row + 1) cells, as this is sufficient
        // to keep track of cells on the left and on the top of the current
        // cell.
        Cell* cells = malloc((array->size + 1) * sizeof(Cell));
        if (cells != NULL) {

            // No square has been found yet.
            square->size = 0;

            // Go through the whole array, from top to bottom and from left to
            // right...
            uint16_t blockId = 0;
            uint8_t cellId = 0;
            uint8_t cellIdPrevious = array->size;
            for (uint8_t y = 0; y < array->size; ++y) {
                for (uint8_t x = 0; x < array->size; ++x) {

                    // Define the next cell ID (which is also the ID of the cell
                    // on the top of the current cell).
                    // Note: similarly, the previous cell ID is also the ID of
                    // the cell on the left of the current cell... and the
                    // current cell ID is also the ID of the cell in its upper-
                    // left corner!
                    uint8_t cellIdNext = cellId < array->size ? cellId + 1 : 0;

                    // Check whether there is a block here.
                    Cell cell;
                    if (!array->blocks[blockId]) {

                        // No block!
                        cell.squareSize = 0;
                        cell.rowLength = 0;
                        cell.columnHeight = 0;
                    } else {

                        // All fields of the corresponding cell can be
                        // initialized to 1.
                        cell.squareSize = 1;
                        cell.rowLength = 1;
                        cell.columnHeight = 1;

                        // Check whether it is neither the first row nor the
                        // first column (so, we can check neighbor cells on the
                        // left and on the top of the current cell).
                        // Note: we could update rowLength when on the first
                        // row, and we could update columnHeight when on the
                        // first column... but this would be useless, actually.
                        if (x > 0 && y > 0) {

                            // Update the cell's fields with values from the
                            // neighbor cells (size of the square in the
                            // upper-left corner, length of the row on the left,
                            // and height of the column on the top).
                            cell.squareSize += cells[cellId].squareSize;
                            cell.rowLength += cells[cellIdPrevious].rowLength;
                            cell.columnHeight += cells[cellIdNext].columnHeight;

                            // The actual square size here is limited by the row
                            // length and column height, of course.
                            if (cell.squareSize > cell.rowLength) {
                                cell.squareSize = cell.rowLength;
                            }
                            if (cell.squareSize > cell.columnHeight) {
                                cell.squareSize = cell.columnHeight;
                            }
                        }

                        // Check whether this square is the largest found so
                        // far.
                        if (cell.squareSize > square->size) {

                            // Take note of this square.
                            square->size = cell.squareSize;
                            square->bottomRightX = x;
                            square->bottomRightY = y;
                        }
                    }

                    // Record the cell data (to allow update neighbor cells in
                    // the future).
                    cells[cellId] = cell;

                    // Next block / next cell...
                    ++blockId;
                    cellIdPrevious = cellId;
                    cellId = cellIdNext;
                }
            }

            // Free the memory allocated to store the cells.
            free(cells);

            // All good!
            error = Success;
        }
    }

    // Done.
    return error;
}

// Main program (entry point).
int main(int argc, char** argv) {
    Error error = Failure;

    // Set the seed of the pseudo random number generator (to have different
    // results every time).
    srand(time(NULL));

    // Define the array with a default size of 8x8 blocks.
    Array array = {.size = 8};

    // Define the default percentage of blocks in the array (60%).
    uint8_t percentageBlock = 60;

    // If there is at least 1 argument on the command line, then use it to
    // define the size of the array.
    if (argc > 1) {
        int arg1 = atoi(argv[1]);
        if (arg1 < 0) {
            array.size = 0;
        } else if (arg1 > 255) {
            array.size = 255;
        } else {
            array.size = arg1;
        }

        // If there is a 2nd argument on the command line, then use it to define
        // the percentage of blocks.
        if (argc > 2) {
            int arg2 = atoi(argv[2]);
            if (arg2 < 0) {
                percentageBlock = 0;
            } else if (arg2 > 100) {
                percentageBlock = 100;
            } else {
                percentageBlock = arg2;
            }
        }
    }

    // Create the array.
    error = CreateArray(&array, percentageBlock);
    if (error == Success) {

        // Display the array (we do not care about errors here).
        DisplayArray(&array);

        // Search for the largest square in the array.
        Square square = {.size = 0};
        error = SearchArray(&array, &square);

        // Display the results.
        if (error == Success) {
            if (square.size > 0) {
                printf("\nLargest square = %dx%d at (%d, %d).\n",
                        square.size, square.size,
                        square.bottomRightX + 1 - square.size,
                        square.bottomRightY + 1 - square.size);
            } else {
                puts("\n(No block at all!)");
            }

            // If there was no argument on the command line, then display the
            // usage.
            if (argc == 1) {
                printf("\nUsage: %s [array_size [percentage_of_blocks]]\n"
                        "Example: %s 10 90\n",
                        argv[0],
                        argv[0]);
            }
        }

        // Destroy the array (we do not care about errors here).
        DestroyArray(&array);
    }

    // Done.
    return error;
}
