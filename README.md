<img src="https://github.com/yenchulin/Parking/raw/master/Parking_logo.png" width=200>

# 司馬亭 - User Client
> An iOS client app for a smart parking solution targeting to provide seamless parking experience.

Finding street parking is a constant headache. Inefficient traditional parking systems lead to revenue loss and force drivers to endure a cumbersome, manual payment process.

司馬亭 is an award-winning project from the Shanghai Youth Maker Competition that redefines urban parking through hardware ground sensors LPWAN and a real-time cloud backend to track parking availability and duration down to the exact second. 

Users can easily find available parking spaces on the map, navigate to them, and experience a completely "ticketless" automated checkout process when they drive away.

## Features
* **Real-time Availability:** View available parking spots on an interactive map.
* **Auto-Checkout:** Leveraged WebSockets to push real-time notifications to the user the moment they leave the parking spot.
* **Seamless Payment:** Integrated with Stripe for secure and automatic parking fee deductions.

## Requirements

* iOS 10.0+
* Xcode 9.0+

## Documentation

Description of the files and directories.

### 📁 Parking
> The main directory that contains the application source code (MVC Architecture).
* **Models:** e.g., `User.swift`, `ParkingSpaceAnnotation.swift`.
* **Controllers:** e.g., `ParkingMapViewController.swift`, `LoginViewController.swift`, `CreditCardViewController.swift`.

### 📄 Podfile
> A file that states the frameworks installed in the app.

* **Alamofire** for handling RESTful API requests (fetching parking lists, pending checks).
* **SwiftyJSON** for extracting and parsing JSON responses elegantly.
* **SwiftPhoenixClient** for handling WebSocket connections with the Elixir/Phoenix backend to receive real-time parking status and payment requests.
* **Stripe** for processing secure credit card payments.
* **KeychainAccess** for securely storing sensitive user data (like user tokens and IDs).
* **SCLAlertView** for beautifying in-app alert dialogs (e.g., payment success notifications).
* **ReachabilitySwift** for monitoring the device's network connection status.

### 🌱 Native Frameworks
* **MapKit & CoreLocation** for rendering the map, managing custom parking pins, and tracking user location.
