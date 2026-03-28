import SwiftUI

// Each case maps to an image asset name for Clearus' facial expressions (some assets might not be used)
enum ClearusExpression: String {
    case talking
    case amazed = "immuneCellAmazed01Allergyzz"
    case blinking = "immuneCellBlinkingAllergyzz"
    case disappointed = "immuneCellDisappointedAllergyzz"
    case happy = "immuneCellHappyAllergyzz"
    case sad1 = "immuneCellSad01Allergyzz"
    case sad2 = "immuneCellSad02Allergyzz"
    case scared = "immuneCellScaredAllergyzz"
    case stressed = "immuneCellStressedAllergyzz"
}
