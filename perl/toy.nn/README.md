# Toy Perceptron Neural Network

Inspired by Coding Train videos and code
<https://github.com/CodingTrain/Toy-Neural-Network-JS>
- XOR: <https://www.youtube.com/watch?v=188B6k_F9jU>
- State of code after last "backprop" video <https://github.com/CodingTrain/Toy-Neural-Network-JS/tree/5c1e9f46bdb125aff84cfe703664a474f319d320>

------------------------------

## Notes ##

### TODO

☐: TODO | ✓: DONE | ✗: DECIDE_NO

☐ backpropagate improvement: neither layer nor network uses the Q/Y input, so why bother?
✓ PerceptronLayer
    ✓ Init
    ✓ Feedforward
    ✓ Backprop
    ✓ Spreadsheet: known-good calculations for verifying backprop, to be used in layer.t
    ✓ test: layer.t -- single layer "XOR" (really just the AND and OR outputs)
✓ PerceptronNetwork
    ✓ Init
    ✓ Feedfoward
    ✓ Backprop
    ✓ Check single layer
    ✓ Check multiple layers
    ✓ Spreadsheet: add another tab, this time doing a two-layer XOR, not just the AND and OR components for the hidden layer
    ✓ test: network.t -- two-layer XOR
✗ Consider Bias & Weights combo -- see below; for now, decided NO
✓ Add fn()=tanh, df()=d(tanh) and function-chooser
✓ Coding Challenge: XOR
☐ Coding Challenge: Doodle Classifier



### Bias & Weights

Part of me wanted to switch from two separate weights and bias matrixes to a biased-weights matrix.
I checked on some scratch paper.  The dimensions work out if I:
- Augment the initial X matrix by a row of all 1s
    ```
    [ X1a X1b X1c X1d ]     becomes     [ X1a X1b X1c X1d ]
    [ X2a X2b X2c X2d ]                 [ X2a X2b X2c X2d ]
                                        [ 1   1   1   1   ]
    ```
- Append the B column matrix as the rightmost colum in the combined W matrix
  _and_ augment with an extra row of all 0s, except the Bias column is a 1:
    ```
    W           B
    [ W11 W12 ] [ B1 ]    becomes       [ W11 W12 W1B ]
    [ X21 X22 ] [ B2 ]                  [ X21 X22 B2B ]
    [ ... ... ] [ .. ]                  [ ... ... ... ]
    [ Wn1 Wn2 ] [ Bn ]                  [ Wn1 Wn2 WnB ]
                                        [ 0   0   1   ]
    ```
- If you do that weight-append_bias-augment_0001 for all the weights,
  then the final output will have an extra row.  So your choices are
  1. _not_ do the augment_0001 for the last weights,
     and use your TARGET as-is
  _or_
  2. de-augment the final Y (remove the dummy row),
     but then you'll have to make sure the E = TARGET - Y
     is re-augmented so that it matches the internal dimensions

But whichever of those two you pick, the dimensions will all work out
for both the per-layer backprop and the error backprop between layers,
so that all the right things are multiplied and subtracted.

However, that's a lot of extra logic to decide when to do the augmentation,
and extra appending/removal of rows (the column insertion isn't a problem,
because that's just one time during setup), and I don't know that
"augment X then W-times-X then de-augment Y" is really significantly faster
than "W-times-X plus B".

For now, I won't implement it... but if I ever do:
- PerceptronLayer would just eliminate it's B matrix; everything else
  in the single Layer would stay the same
- PerceptronNetwork would have to be where it does the augment/deaugment:
  - initialization:
    - size(W) = (nH + 1) rows by (nX + 1) cols
    - last row of W would have to be initialized to 0001
  - Feedforward:
    - A = aug(X)
    - Loop { Q=feedforward(X); nextX = Q } -- no change
    - Y = deAug(Q)
  - Backprop(X,Y,T)
    - A = aug(X)
    - Loop { Q_i = feedforward(X_i); X_{i+1} = Q_i } -- no change
    - InternalT = aug(T)
    - E_n = InternalT - Q_n
    - LoopBackwards { backprop(X_i,Q_i,E_i); E_{i-1} = transpose(W_i) x E_i } -- no change

