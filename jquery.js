// And here we have some mysterious javascript snippet
//
// Let's try to answer some questions here:
// 1. Can you guess what it does in general?

// It looks like some element from the form in which the user has the possibility 
// to select from existing variants of range or set a custom date by date picker.
// Select element has some limits of possible variants. And only one of them can be changed.

// 2. How would you implement such thing? Would you use
// similar approach or something totally different or maybe in-between?

// We have an input element which not visible to the user. It is an approach 
// used in general before. In case jQuery is a good variant. But using new 
// technology we don't need to use the hide input field. I don't see the full 
// picture and I can't answer this question. Regarding available code, 
// it is a good approach. 


// 3. Can you point some obvious and less obvious issue with this code?
// I see some problems with the previous code:
// - Some functionality duplicates
// - Hardly support changes on text for select options. previously text changed in 
//   3 places and it is very hard to support. This code replaced to function with attributes.
// - As I see this code is not full, because no available function to set the value to hide input 
//   with a specific id (#job_job_completion_date).


//
// Again please prepare secret gist with the answers!

// Changed code is bellow.
//
$(document).ready(function() {
    var $dateInput = $("#job_job_completion_date");
    var datePickerIndex = 3
  
    if (!$dateInput.length) { return }
  
    $dateInput.hide();
  
    // Create elements
    var $select = $("<select>");
  
    var $datePicker = $("<input>", { type: "text", readonly: true });
  
    var $datePickerBtn = $("<button>", {
            html: '<i class="fa fa-calendar" aria-hidden="true"></i>'
          , class: "open-date-picker"
         });
  
    // Helpers
  
    var setValues = function(inputValue, selectValue) {
      $dateInput.val(inputValue);
      $select.find("option").eq(datePickerIndex).text("Select: " + (selectValue || inputValue)).attr('selected', true);
    }
  
    // Set select options
  
    var values = $dateInput.data("values").split(",");
  
    $select.append(values.map(function (c, i) {
      return $("<option>", { text: c, value: c, "data-index": i });
    }));
  
    // Existing value
  
    if ($dateInput.val()) {
      setValues(existingValue)
    }
  
    // Event listeners
  
    $datePickerBtn.hide().click(function () {
      $datePicker.show().focus().hide();
      return false;
    });
  
    $datePicker.datepicker({ minDate: 0 }).hide().on("change", function () {
      setValues(this.value)
    });
  
    $select.on("change", function () {
        if (+$(this).find("option:selected").data("index") === datePickerIndex) {
            $dateInput.val('');
            $datePickerBtn.show().click();
        } else {
            $datePickerBtn.hide();
            $datePicker.hide();
            setValues(this.value, 'please choose data');
        }
    });
  
    // Innit
    $select.change();
    $dateInput.before([$select, $datePickerBtn, "<br>", $datePicker]);
  });
  
