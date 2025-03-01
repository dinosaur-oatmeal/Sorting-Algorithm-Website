module Trees.TreeVisualization exposing (view)

-- HTML Imports
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)

-- SVG imports for creating tree
import Svg exposing (Svg, svg)
import Svg.Attributes exposing
    ( x1, y1, x2, y2
    , cx, cy, r, fill, stroke, strokeWidth
    , width, height, style
    , x, y, textAnchor, fontSize
    )

-- Import necessary structure for visualization
import MainComponents.Structs exposing (Tree(..))

-- PositionedTree (binary tree type)
type PositionedTree
    = PositionedNode
        -- Value at of node
        { val : Int
        -- Coordinate in X direction
        , x : Float
        -- Coordinate in Y direction
        , y : Float
        -- Left child (if any)
        , left : Maybe PositionedTree
        -- Right child (if any)
        , right : Maybe PositionedTree
        }

-- VIEW
view : Tree -> Maybe Int -> Maybe (Int, Int) -> List Int -> Bool -> Html msg
view tree maybeCurrentIndex maybeSwapIndex traversalResult running =
    let
        -- Node to be highlighted in tree
            -- Don't highlight before Run or Step
        maybeActiveVal =
            currentIndexNode traversalResult maybeCurrentIndex

        -- Total nodes in the tree
        totalNodes =
            countNodes tree

        -- Compute tree positioning
            -- Root should always be positioned
        ( maybePositionedRoot, _ ) =
            -- Get coordinated as PositionedTree type
                -- tree, initial X, update to X, initial Y, update to Y
            layoutHelper tree 500 25 40 75
    in
    div [ class "tree-page" ]
        [ case maybePositionedRoot of
            -- Root not positioned (shouldn't occur)
            Nothing ->
                div [] 
                    [ text "Empty Tree" ]

            -- Root positioned and tree generated
            Just positionedRoot ->
                -- Renders SVG onto the screen
                svg
                    -- Size of SVG viewport
                    [ width "1000"
                    , height "375"
                    -- Ease into new colors
                    , Svg.Attributes.style "transition: fill 0.6s ease"
                    ]
                    -- Receive lists of SVG elements to render
                    (lines positionedRoot ++ nodes positionedRoot maybeActiveVal maybeSwapIndex)

        -- Display traversal progress for tree traversal but not for heaps
        , case maybeCurrentIndex of
            Just currentIndex ->
                div []
                    [ text ("Traversal so far: " ++ renderHighlighted traversalResult (Just currentIndex)) ]
            Nothing -> text ""
        ]

-- Finds node to highlight
currentIndexNode : List Int -> Maybe Int -> Maybe Int
currentIndexNode traversal maybeIdx =
    case maybeIdx of
        Just idx ->
            if idx > 0 && idx <= List.length traversal then
                -- Last node in traversal list
                List.head (List.drop (idx - 1) traversal)

            -- Don't highlight anything if traversal list is empty
            else
                Nothing
        
        _ ->
            Nothing

-- Counts nodes in a tree
countNodes : Tree -> Int
countNodes node =
    case node of
        -- Tree is empty
        Empty -> 0

        -- Add 1 and recursively call countNodes for children
        TreeNode _ left right -> 1 + countNodes left + countNodes right

-- Renders the highlighted node
renderHighlighted : List Int -> Maybe Int -> String
renderHighlighted xs maybeIdx =
    case maybeIdx of
        Just idx ->
            let
                visited =
                    List.take idx xs

                visitedStr =
                    "[" ++ String.join ", " (List.map String.fromInt visited) ++ "]"
            in
            visitedStr

        _ ->
            "No step"

-- Get X and Y coordinates of each node in the tree (pre-order traversal)
layoutHelper : Tree -> Float -> Float -> Float -> Float -> (Maybe PositionedTree, Float)
layoutHelper tree x dx y dy =
    case tree of
        -- No root positioned if tree is empty
        Empty ->
            ( Nothing, x )

        -- Process the node to find coordinates
        TreeNode val left right ->
            let
                -- Layout left subtree
                ( maybeLeftTree, leftSubtreeWidth ) =
                    layoutHelper left (x - 6 * dx) (dx / 2) (y + dy) dy

                -- Layout right subtree
                ( maybeRightTree, rightSubtreeWidth ) =
                    layoutHelper right (x + 6 * dx) (dx / 2) (y + dy) dy

                -- Recalculate X coordinate for current node
                currentX = x

                -- Create positioned node
                updatedNode =
                    PositionedNode
                        { val = val
                        , x = currentX
                        , y = y
                        , left = maybeLeftTree
                        , right = maybeRightTree
                        }
            in
            -- Return updated node and subtree width (left = right)
            ( Just updatedNode, rightSubtreeWidth )

-- Draw lines from parent nodes to children
    -- Return a list of SVG elements to be rendered
lines : PositionedTree -> List (Svg msg)
lines tree =
    case tree of
        PositionedNode node ->
            let
                -- return an SVG line from parent X/Y to child X/Y
                parentToChild childNode =
                    Svg.line
                        [ x1 (String.fromFloat node.x)
                        , y1 (String.fromFloat node.y)
                        , x2 (String.fromFloat childNode.x)
                        , y2 (String.fromFloat childNode.y)
                        -- Color and width of line
                        , stroke "#808080"
                        , strokeWidth "2"
                        ]
                        []

                -- Left child lines
                leftLines =
                    case node.left of
                        -- Internal nodes
                        Just childTree ->
                            case childTree of
                                PositionedNode childNode ->
                                    -- Recursively call lines to draw child's children etc.
                                    parentToChild childNode :: lines childTree

                        -- Leaf nodes
                        _ ->
                            []

                -- Handle the right child
                rightLines =
                    case node.right of
                        -- Internal nodes
                        Just childTree ->
                            case childTree of
                                PositionedNode childNode ->
                                    -- Recursively call lines to draw child's children etc.
                                    parentToChild childNode :: lines childTree

                        -- Leaf nodes
                        _ ->
                            []
            
            -- Add lists together
            in
            leftLines ++ rightLines

-- Draw nodes in tree
    -- Change color if they're selected
nodes : PositionedTree -> Maybe Int -> Maybe (Int, Int) -> List (Svg msg)
nodes tree maybeActive maybeSwapIndex =
    case tree of
        PositionedNode node ->
            let
                isActive =
                    case maybeActive of
                        -- Node should be highlighted
                        Just x ->
                            x == node.val

                        -- Node should not be highlighted
                        _ ->
                            False

                isSwapped =
                    case maybeSwapIndex of
                        Just (a, b) ->
                            node.val == a || node.val == b

                        _ ->
                            False


                -- Determine circle color if node active
                circleColor =
                    if isActive || isSwapped then
                        "#FF5722"
                        
                    else
                        "#64B5F6"

                -- Draw circle at X/Y coordinates given in PositionedNode
                myCircle =
                    Svg.circle
                        [ cx (String.fromFloat node.x)
                        , cy (String.fromFloat node.y)
                        , r "15"
                        , fill circleColor
                        , Svg.Attributes.style "transition: fill 0.5s ease"
                        ]
                        []

                -- Draw text at X/Y coordinates given in PositionedNode
                label =
                    Svg.text_
                        [ x (String.fromFloat node.x)
                        -- Add to Y to center text
                        , y (String.fromFloat (node.y + 5))
                        , fill "white"
                        , fontSize "14"
                        , textAnchor "middle"
                        ]
                        [ Svg.text (String.fromInt node.val) ]


                -- Recursively call left child nodes to be drawn
                leftNodes =
                    case node.left of
                        Just l ->
                            nodes l maybeActive maybeSwapIndex

                        -- Leaf nodes
                        _ ->
                            []

                -- Recursively call right child nodes to be drawn
                rightNodes =
                    case node.right of
                        Just r ->
                            nodes r maybeActive maybeSwapIndex

                        -- Leaf nodes
                        _ ->
                            []
            
            -- Add root, and children nodes together
            in
            [ myCircle, label ] ++ leftNodes ++ rightNodes
