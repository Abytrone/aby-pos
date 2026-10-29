Phase 7b is done, which finishes Phase 7: branches, transfers between them, and a branch data file for carrying data between branches. All 300 tests pass and both builds succeed. A copy of your real database upgrades to v17 with just the main branch, so nothing changes for Scoops Tamale until a second branch is added.

Branches (Settings → Branches)

Every shop starts with a main branch. You can add more with an address and phone, rename them, or close and reopen them.
How a branch works: each device is placed in a branch, and its sales and stock count for that branch. Devices never placed are in the main branch.
Stock is counted per branch.
Reports and the dashboard get an "All branches / one branch" picker. It only appears once there's a second branch.
Staff can be limited to one branch, and then only see it at sign-in there. Owners can sign in at any branch.
Transfers (Stock → Transfers, shown once there's a second branch)

Stock leaves the sending branch immediately and shows as on its way.
The receiving branch counts what arrived. Any difference is flagged on the transfer and in the activity log.
A transfer not yet received can be called back.
Branch data file

Send this branch's data makes the usual encrypted backup.
At the other branch, Bring in a branch data file merges it in rather than replacing anything:
It takes a safety backup first.
An older file is upgraded before merging.
Where the same record differs, the later edit wins.
Bringing in the same file twice changes nothing.
What came in is passed on to that branch's hub.
Decisions and limits

Branch comes from the device: sales and stock records aren't tagged with a branch; it comes from the device that made them, so old data needed no conversion. The catch is that moving a device to another branch moves its past sales and stock with it. The app warns before doing this.
Not built:
Product prices are the same at every branch.
Profit and loss and the stock movements on a product's page cover all branches.
Receipts still show the shop's name and address, not the branch's.
Fixes along the way

The new mainBranchId constant first landed between the database annotation and its class, which silently stopped the database code from being generated. It's now above the annotation.
dart format would have restyled all of the stock screen, so I reverted that and kept the change to 28 lines.

git add -A; git commit -m "Phase 7b: branches, stock transfers, branch data file" -m "Branches (MDV-02): every shop has the main branch; a branch is the devices placed in it, so sales and stock movements belong to the branch of the device that made them and old rows need no migration. Stock is counted per branch, reports and the dashboard show all branches or one, and staff can be limited to a branch (owners sign in everywhere). Settings has Branches: add, edit, close, and which branch this device is at. Transfers (INV-10): send stock to another branch, in transit until received, differences flagged, call back before it arrives. Branch data file (DAT-03): the encrypted backup carries data between branches and is merged row by row with last-write-wins after a safety backup, queued for the hub. Schema 17 adds branches, device_branches, stock_transfers, stock_transfer_lines and staff.branch_id." 
Next is Phase 8: Aby Cloud and integrations (cloud sync, MoMo APIs, SMS, GRA E-VAT, accounting export, online ordering).