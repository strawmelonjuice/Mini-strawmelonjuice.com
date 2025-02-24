pub const footer = "<footer class='footer footer-center bg-base-300 text-base-content p-1 fixed bottom-0'><aside><p>Made into this website with <a class='dark:text-sky-600 text-sky-800 underline' target='_blank' href='https://github.com/strawmelonjuice/CynthiaWebsiteEngine-mini'>Cynthia Mini</a> by Strawmelonjuice.</p></aside></footer>"

/// The entire <body> of the 404 page.
pub fn notfoundbody() -> String {
  "<div class='absolute mr-auto ml-auto right-0 left-0 bottom-[40VH] top-[40VH] w-fit h-fit'>
<div class='card bg-primary text-primary-content w-96'>
  <div class='card-body items-center text-center'>
    <h2 class='card-title'>404!</h2>
    <p>Uh-oh, that page cannot be found.</p>
    <div class='card-actions justify-end'>
      <button class='btn btn-neutral-300' onclick='javascript:window.location.assign(\"/#/\")'>Go home</button>
      <button class='btn btn-ghost' onclick='javascript:window.history.back(1)'>Go back</button>
    </div>
  </div>
</div>
    </div>
    "
  <> footer
}
