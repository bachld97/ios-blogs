# Quick UICollectionView

In iOS development, we can display a list or a grid of item using `UICollectionView`.
Setting up the `UICollectionView` is a tedious task because it involves a lot of boilerplate code.

There are various tutorial for quick and easy way to create UICollectionView using generics.
However, I think the generics approaches create more complication than it solves.

After search the Internet and tutorials online, I came across a repository called `LBTAComponents` by Brian Voong.
The author uses inheritance on `UICollectionViewController` instead of generics to reuse setup code for `UICollectionView`.

My approach to quick and easy `UICollectionView` is an adaptation from his work.

## Ovevrview

To create a new collection view, we follow 3 steps below:

* Create a subclass of `CollectionDataSource`
* Create a subclass of `CollectionViewCell`
* Create a subclass of `CollectionViewController`

Let us walk through each of the classes introduced above.

## CollectionDataSource

This class serves the data to our collectionView, it functions similarly to UICollectionViewDataSource with simplified interfaces.
Cell registration and dequeue are handled by `CollectionViewController`, so `CollectionDataSource` only supplies cell types for items.

```swift
open class CollectionViewDataSource: NSObject {
    public var items: [Any]? = nil
    
    public init(items: [Any]? = nil) {
        self.items = items
    }
}
```

Firstly, the class is made `open` because we potentially want to extract it out as a Pod library to reuse across multiple projects.
The `CollectionDataSource` holds references to a list of items, which is self-explanatory.
Now we move on to functions of a collection view datasource

```swift
open func numberOfSections() -> Int { return 1 }
open func numberOfItems(inSection section: Int) -> Int { return items?.count ?? 0 }
```

By default, our datasource has one section with the number of items equal to the length of our array.
Now we move on to the most crucial steps: cell class and item binding.

```swift
open func item(at indexPath: IndexPath) -> Any? {
    return items?[indexPath.item]
}

open func cellClass(at indexPath: IndexPath) -> CollectionViewCell.Type? {
    return nil
}

open func cellClasses() -> [CollectionViewCell.Type] {
    return [CollectionViewCell.self]
}
```

To understand `cellClass(at:)` and `cellClasses()` function, we must understand how `CollectionViewController` works.
When a datasource is set for our view controller, it calls to `cellClasses()` to register cells for our `UICollectionView`.
After that, when `collectionView(_:,cellForItemAt:)` is called, the view controller asks the datasource for `cellClass(at:)`.
If it finds `nil`, it assumes that each cell class from `cellClasses()` corresponds to a section.
If current indexPath gives a section greater than the number of cells in `cellClasses()`, our collectionView will get the first cell class in `cellClasses()`.

If all of the above fails, it uses the default cell type.
More discussion on how to handle this case in later section.

The same logic applies to headers and footers.
For brevity, it will not be included.


## CollectionViewCell

This is our default cell class, which supports a line divider, a `prepareUI()` method, and an item of type Any.

```swift
open class CollectionViewCell: UICollectionViewCell {
    public var item: Any?
    open var lineDivider: UIView = {
        let view = UIView()
        // Configure lineDivider
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepareUI()
    }

    open func prepareUI() {
        clipsTobound = true
        addSubview(lineDivider)
        // Configure lineDivider's height and position
    }
}
```

Again, the class is made open due to the exact same reason as above.
`prepareUI()` helps us avoid overriding `init()`, which is annoying to override because it forces use to have `required init?(coder:)`

To bind the item, I am aware of two approaches.

```swift
// Approach 1
public var item: Any? { didSet { configureCell() } }
open func configureCell() { ... }

// Approach 2
open func configureCell(with item: Any) { 
    self.item = item
    ....
}
```

Personally I prefer the first approach because it simplifies the cell binding call site - `cell.item = item` instead of `cell.configure(with: item)`.
Another reason is that in the second approach, we might forget to call `super.configureCell(with:)` and the item within the cell will not be available in case we need it elsewhere.

Lastly, let's go over the `CollectionViewController`, the final piece connecting our cells and datasource.

## CollectionViewController

```swift
open class CollectionViewController: UICollectionViewController, UIColelctionViewDelegateFlowLayout {
    open var dataSource: CollectionViewController? {
        didset {
            registerCells()
            registerHeaders() // Similar to registerCells
            registerFooters() // Similar to registerCells
            dataSource(didChangeFrom: oldValue)
        }
    }

    private func registerCells() { 
        for cls in dataSource?.cellClasses() ?? [] {
            collectionView?.register(
                cls, forCellIdentifier: NSStringFromClass(cls)
            )
        }
    }

    open func dataSource(didChangeFrom oldSource: CollectionViewDataSource) {
        // We can use diff frameworks to implement cell transitions
        collectionView.reloadData()
    }
}
```

Number of sections and number of items in sections is trivial to implement.
I will discuss the dequeue process next, as it is the most important function in this approach.

```swift
 override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: CollectionViewCell
        let cellClass: CollectionViewCell.Type
        
        if let cls = dataSource?.cellClass(at: indexPath) {
            cellClass = cls
        } else if let cls = dataSource?.cellClasses().first {
            cellClass = cls
        } else {
            // Optionally, we can make our application crashes here.
            // Because lack of cell class is probably a programming error.
            assert(false) // Or make it fail in development, use default in production
            cellClass = CollectionViewCell.self
        }

        let cellId = NSStringFromClass(cellClass)
        cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: cellId, for: indexPath
        ) as! CollectionViewCell
        
        cell.item = dataSource?.item(at: indexPath)
        cell.cellDelegate = self // Explain right below
        return cell
}
```

We can use `collectionView(_:,didSelectItemAt:)` to handle click, but for more complicated cells, this is not sufficient.
As a result, let us define another variable within the cell class.

```swift
// Inside CollectionViewCell

public weak var cellDelegate: CellDelegate? {
    didSet { configureDelegate() }
}

// Example usage in derived class
open func configureDelegate() {
    if let concreteDelegateForCell = cellDelegate as? ConcreteDelegateForCell {
        self.concreteDelegateForCell = cellDelegate
    }
}

protocol CellDelegate: class { }
```

`CellDelegate` is just an empty protocol, derived cell classes should hold references to a concrete cell delegate.
`configureDelegate()` is not really necessary, but it simplifies code in derived classes.
The simplification is worth it because for a complicated cell, the number of places calling `cellDelegate` is probably more than three.
Alternatively, we can use `AnyClass?` in place of `CellDelegate?`, or use typealias `typealias CellDelegate = AnyClass`.

For full code corresponding to this post, head over to my [Github repository](www.google.com)

## Reference

(List out a few generic approaches and link to `LBTAComponents`)


