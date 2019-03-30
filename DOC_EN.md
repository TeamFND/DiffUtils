# class DiffUtils

- procedure Insert(i:integer;elem:T) - adds element by index and value
- procedure AddElem(elem:T) - adds element by value to the end of the list
- procedure Remove(index:integer) - removes element from the list by number
- procedure Clear() - removes all elements from the list
- procedure GoBack() - cancels last change in history
- procedure GoForward() - does the last cancelled changу again
- procedure ClearHistory() - removes all records from hstory
- property HistoryCountBack - returns amount of elements before current state
- property History - returns full change history 
- property HistoryCountForward - returns amount of elements after current state
- property Items - allows access to elements by index given in square braces
- property Count - returns number of elements in the List

# record THistoryItem

- index - integer field storing index of changed element
- action - enum field storing type of change
- value - field storing value of element with the given index
- OldValue - field storing value that was set to element before this change in history

# Main features

* Create the list oа elements of any data type with possibility to reverse your changes
* Modify the list
  + insert items into the position
  + add items at the end of the list
  + remove certain element
  + replace certain element with any other value
  + clear the list
* List has got change history
  + Every change is logged
  + History can be cleared
  + You can
    * Reverse any changes
    * Make this changes again (using еоу history conmmand)
    * When you make new changes all history after this state is being erased
