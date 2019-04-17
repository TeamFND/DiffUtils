# class DiffUtils

- procedure Insert(i:integer;elem:T) - adds element by index and value
- procedure InsertRange(i:integer;elems:array of T) - adds array of elements to the end of the list
- procedure Add(elem:T) - adds element by value to the end of the list
- procedure AddRange(elem:array of T) - adds range(array) to the end of the list
- procedure Remove(index:integer) - removes element from the list by number
- procedure RemoveRange(index:integer;length:integer) - removes array of elements from the list by number and length
- procedure SetRange(index:integer;elems:array of T) - allows you to set range of elements by start index and array
- procedure Clear() - removes all elements and histoy from list
- procedure ClearHistory() - removes all records from history
- procedure GoBack() - cancel last change
- procedure GoForward() - does the last cancelled change again
- property HistoryCountBack:integer - amount of elements before current state
- property HistoryCountForward:integer - amount of elements after current state
- property History[index:integer]:THistoryItem - change history(0-lats, 1-before last, -1-next)
- property Items[index:integer]:T - list
- property Count:integer - number of elements in the List

# record THistoryItem

- index - index of changed elements
- action - type of change
- value - new values of elements
- OldValue - old values of elements

# Main features

* Create the list oа elements of any data type with possibility to reverse your changes
* Modify the list
  + Insert items into the position
  + Add items to the end of the list
  + Remove certain element
  + Replace certain element with any other value
  + Clear the list
* List has got changes history
  + Every change is logged
  + History can be cleaned
  + You can
    * Reverse any changes
    * Make this changes again using еоу history command
  + When you make new changes all history after this state is being erased
