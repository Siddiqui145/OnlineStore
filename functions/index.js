const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

// When a customer places an order / service request, email every admin.
// Emails are sent by the "Trigger Email from Firestore" extension, which
// watches the `mail` collection.
exports.notifyAdminsOnOrder = onDocumentCreated("orders/{orderId}", async (event) => {
  const o = event.data.data();
  const db = admin.firestore();

  const admins = await db.collection("users").where("role", "==", "admin").get();
  const to = admins.docs.map((d) => d.get("email")).filter(Boolean);
  if (to.length === 0) return;

  const isService = o.type === "service";
  const lines = isService
    ? `<p><b>Service:</b> ${o.serviceType || "-"}</p><p>${o.notes || ""}</p>`
    : `<ul>${(o.items || []).map((i) => `<li>${i.qty} x ${i.name}</li>`).join("")}</ul><p><b>Total:</b> ${o.total}</p>`;

  await db.collection("mail").add({
    to,
    message: {
      subject: `New ${isService ? "service request" : "parts order"} from ${o.customerName}`,
      html: `<h3>${isService ? "Service request" : "Parts order"}</h3>
             ${lines}
             <p><b>Customer:</b> ${o.customerName}<br>
             <b>Phone:</b> ${o.phone}<br>
             <b>Email:</b> ${o.email}<br>
             <b>Address:</b> ${o.address}</p>
             <p>Open the admin dashboard to update the status.</p>`,
    },
  });
});
