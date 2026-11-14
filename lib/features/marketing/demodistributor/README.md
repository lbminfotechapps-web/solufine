# Demo Distributor

Route: `/demoDistributor`. Clean architecture: presentation (Cubit, page,
debounced option picker), domain (entities, repository contract, use cases),
data (existing lookup APIs, repository implementation, draft model).
Composition lives in `lib/core/di/demo_distributor_di.dart`.

Fields follow the two reference screenshots. State changes clear district/block;
crop changes clear subcategory/variety; subcategory changes clear variety.
Only selected API options satisfy required search fields. Quantity is a finite
positive number. Search waits one second and ignores stale responses.
Success prevents repeat submission and requires OK to leave the dialog.

## Integration still needed

No confirmed Demo Distributor submit endpoint/request mapping was present.
Provide a `DemoDistributorSubmitAdapter` to `createDemoDistributorCubit` to
map the entry to the real API and return a message only after server acceptance.
Without that adapter Submit stays disabled; no fake success or guessed URL is used.
`DemoDistributorModel.toDraftJson()` is a local draft, not an API contract.

Customer types currently use Farmer/Dealer/Distributor labels; confirm allowed
values and backend IDs. Showing Date, T P Date, C K, and Field Day retain the
reference labels. C K and Field Day are required text until business rules are
confirmed. Irrigation and previous-year product are optional as shown.
Block currently uses the existing taluka lookup; confirm this mapping.
Subcategory ID/name mapping follows the existing class-record response.

Open from a menu with `context.push(AppRouter.demoDistributor)`.
