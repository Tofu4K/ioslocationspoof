# MapKit Directions & Routing Architecture

**Verification Date:** September 2026  
**Primary Source:** [Apple Developer — MKDirections](https://developer.apple.com/documentation/mapkit/mkdirections)  
**Primary Source:** [Apple Developer — MKRoute](https://developer.apple.com/documentation/mapkit/mkroute)  
**Primary Source:** [Apple Developer — MKPolyline](https://developer.apple.com/documentation/mapkit/mkpolyline)

---

## 1. Overview of MapKit Directions

`MKDirections` provides server-side driving, walking, and transit route calculation without recurring developer API costs:

```swift
let request = MKDirections.Request()
request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoordinate))
request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
request.transportType = .automobile
request.requestsAlternateRoutes = false

let directions = MKDirections(request: request)
let response = try await directions.calculate()
guard let route = response.routes.first else { throw RoutingError.noRouteFound }
```

---

## 2. Extracting High-Fidelity Geometry from `MKRoute`

`MKRoute.polyline` contains the sequence of `CLLocationCoordinate2D` points describing the turn-by-turn road geometry:

```swift
let pointCount = route.polyline.pointCount
var coordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
route.polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
```

### Key Considerations for Simulation:
1. **Preserving Turns:** The raw polyline includes detailed curvature points. We must NOT downsample or aggressively simplify these vertices, as doing so leads to visible corner-cutting across buildings and off-road artifacts.
2. **Segment Distance & Bearing:** For each adjacent pair $(P_i, P_{i+1})$, the simulation engine calculates:
   - Great-circle distance using Haversine / Vincenty formula.
   - Cumulative route distance from the start point.
   - Initial bearing / heading angle in degrees $[0, 360)$.
3. **Multi-Stop Waypoints ($A \to W_1 \to W_2 \to B$):** `MKDirections.Request` connects a single origin to a single destination. To support arbitrary intermediate waypoints, the routing engine issues consecutive requests for each leg $(A \to W_1, W_1 \to W_2, \dots)$ and stitches the polyline segments into a unified `RouteDefinition`.

---

## 3. Fallbacks and Offline Routing

- If Apple's routing service fails (e.g. no internet connection or routing impossible across water), the application presents a clear diagnostic error and preserves the user's selected points.
- The route domain is decoupled behind `RoutingServiceProtocol` so custom routing providers (e.g., local OSRM, Valhalla, or GeoJSON/GPX tracks) can be swapped in seamlessly.
