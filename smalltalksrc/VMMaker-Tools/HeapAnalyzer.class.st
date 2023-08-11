"
First, in a Playground, execute this script to start the simulator with the current image:

```st
InterpreterStackPages initialize.
options := {
    #ObjectMemory -> #Spur64BitCoMemoryManager.
    #BytesPerWord -> 8
} asDictionary.

c := StackInterpreterSimulator newWithOptions: options.
c openOn: Smalltalk imagePath extraMemory: 100000.
""c run.""
```

With that, you will have the stack interpreter simulator loaded with the current image. Inspect the simulator variable `c`.

After, execute this script to take the objects that have at least 100 instances.

```st
self associations select: [ :assoc | | dict |
	dict := assoc value.
	dict anyOne size > 100 ]
```

This other script selects the objects that have at least an instance `LargePositiveInteger` in one of the instance variables.

```st
self select: [ :e | e value anySatisfy: [ :v | v asSet includes: 'LargePositiveInteger' ] ]
```
"
Class {
	#name : #HeapAnalyzer,
	#superclass : #Object,
	#instVars : [
		'simulator',
		'types'
	],
	#category : #'VMMaker-Tools-VM-Dojo'
}

{ #category : #api }
HeapAnalyzer >> analize: anOop [

	(self instanceVariablesOf: anOop) doWithIndex: [ :instVarOop :index |
		self recordTypeOf: anOop at: index with: (self classNameOf: instVarOop) ].
	"Arrays"
	(self variableVariablesOf: anOop) do: [ :instVarOop |
		self recordTypeOf: anOop at: 'var' with: (self classNameOf: instVarOop) ]
]

{ #category : #defaults }
HeapAnalyzer >> classNameOf: anInteger [

	| className |
	className := simulator coInterpreter nameOfClass: (simulator fetchClassOf: anInteger).
	"In type theory, each array that stores different types has a different type. For that
	reason, we cocatenate the oop ID"
	className = 'Array' ifTrue: [ ^ className , anInteger asString ].
	^ className
]

{ #category : #'as yet unclassified' }
HeapAnalyzer >> initialize [

	super initialize.
	types := Dictionary new
]

{ #category : #defaults }
HeapAnalyzer >> instanceVariablesOf: rcvr [
	"I return the fixed instance variables of the receiver. I don't take into account the
	variable variables, as the ones of Array for example."

	| header format totalLength fixedFields |
	header := simulator baseHeader: rcvr.
	format := simulator formatOfHeader: header.
	totalLength := simulator lengthOf: rcvr format: format.
	fixedFields := simulator fixedFieldsOf: rcvr format: format length: totalLength.
	^ (1 to: fixedFields) collect: [ :index |
		  simulator fetchPointer: index - 1 ofObject: rcvr ]
]

{ #category : #defaults }
HeapAnalyzer >> recordTypeOf: oop at: index with: referencedClassName [

	| storer |
	storer := types at: (self classNameOf: oop) ifAbsentPut: [ Dictionary new ].

	storer
		at: index
		ifPresent: [ :col | col add: referencedClassName ]
		ifAbsentPut: [ Bag new
			add: referencedClassName;
			yourself ]
]

{ #category : #accessing }
HeapAnalyzer >> simulator: aSpur64BitMMLECoSimulator [

	simulator := aSpur64BitMMLECoSimulator
]

{ #category : #defaults }
HeapAnalyzer >> variableVariablesOf: rcvr [

	"I return the variable variables of the receiver."
	
	"In this initial version, I only return the variable variables for Array format."
	(simulator formatOf: rcvr) = simulator arrayFormat ifFalse: [ ^ #(  ) ].

	^ (1 to: (simulator stSizeOf: rcvr)) collect: [ :index |
		  simulator fetchPointer: index - 1 ofObject: rcvr ]
]
