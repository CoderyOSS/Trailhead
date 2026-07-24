# UI Polish Agenda

> Copied verbatim from user request. Each item planned, executed, and committed
> to `main` independently.

## A) Running indicator relocation + logs clear button style

Move the "running" indicator (active jobs view) from the far right to the left
side (left-justified), after the job-selector dropdown, meaning it's to the
right of the dropdown selector. Also make the "clear" button in the logs
viewer into a button with the outline style so it's more obviously a button.

## B) Flow tabs styling + launch button theming + click animation

The flow tabs look like buttons. Make them look like tabs (lower border changed
so the appear connected to the graph region, and they rest along the bottom of
the inside of the top bar). Also, the launch button doesn't look like any of
the other buttons in the theme, so update it to match the theme and also give
it some kind of animation when clicked, like how the injector nodes play a
spinner animation while sending the click event.

## C) Replace arrange-panels icon with VS Code-style 2-column / 2-row icons

Do you have an icon for 2 columns and an icon for 2 rows? These icons (they
exist in VS Code) resemble 2 rectangles side-by-side, one for vertical
orientation and the other horizontal orientation. If so, I want that for the
"arrange panels side by side" button instead of the 2-opposing-arrows that we
have right now.

## D) Theme color switching delays on several elements

When changing theme colors, some of the elements are not updating correctly
until an interaction has happened:

1. The logs text doesn't update immediately, it needs to be cycled like
   changing which panels are visible or which nodes are active for the logs.
2. In the edit view, the left column of the logs region and also the plus
   button to add new workflow tabs both show a delay in switching to the
   current theme colors after the theme is switched.

## E) Active jobs view empty state

When switching to the active jobs view, if no job is selected the graph shows
a workflow anyway. This is misleading and creates additional bugs when the
user interacts with the nodes. The graph should instead have an empty state,
similar to the empty state the graph shows in the edit view when there's no
workflows present in the project. When there are no active jobs, make sure
this component shows.
