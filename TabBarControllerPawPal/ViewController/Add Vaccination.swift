//
//  Add Vaccination.swift
//  TabBarControllerPawPal
//
//  Created by admin19 on 02/02/25.
//


import UIKit
import FirebaseFirestore

class Add_Vaccination: UITableViewController, UITextViewDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var vaccineNameButton: UIButton!
    @IBOutlet weak var dateOfVaccinePicker: UIDatePicker!
    @IBOutlet weak var expiresSwitch: UISwitch!
    @IBOutlet weak var expiryDatePicker: UIDatePicker!
    @IBOutlet weak var notifyUponExpirySwitch: UISwitch!
    @IBOutlet weak var notesTextView: UITextView!
    
    // MARK: - Properties
    var petId: String?
    
    // Vaccine list + "Other" option
    let vaccineOptions = [
        "DHPPi", "Kennel Cough", "Distemper", "RL",
        "Lyme Disease", "Lepto", "Parainfluenza",
        "Canine Hepatitis", "Puppy DP", "Rabies",
        "Parvovirus", "Bordatella", "Adenovirus",
        "Other"
    ]
    
    // Track which vaccine is chosen
    var selectedVaccineName: String?
    
    var activityIndicator: UIActivityIndicatorView!
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActivityIndicator()
    }
    
    // MARK: - Setup
    private func setupUI() {
        print("Pet ID: \(petId ?? "No Pet ID passed")")
        
        // Button defaults
        vaccineNameButton.setTitle("Select", for: .normal)
        vaccineNameButton.setTitleColor(.tertiaryLabel, for: .normal)
        
        // Date pickers default
        dateOfVaccinePicker.date = Date()
        expiryDatePicker.date = Date()
        
        // Make the notes text view editable
        notesTextView.delegate = self
        notesTextView.isEditable = true
        // notesTextView.isScrollEnabled = false // if you want it to grow automatically
        
        // Initially hide expiry-related rows if switch is OFF
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }
    
    // MARK: - Actions
    
    @IBAction func expiresSwitchToggled(_ sender: UISwitch) {
        // Animate collapse/expand of expiry date + notify row
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    @IBAction func selectVaccineTapped(_ sender: UIButton) {
        // Present an action sheet with all vaccines, including "Other"
        let alert = UIAlertController(title: "Select Vaccine", message: nil, preferredStyle: .actionSheet)
        
        for vaccine in vaccineOptions {
            alert.addAction(UIAlertAction(title: vaccine, style: .default, handler: { _ in
                if vaccine == "Other" {
                    // Prompt user for a custom vaccine name
                    let inputAlert = UIAlertController(
                        title: "Enter Vaccine Name",
                        message: "Please enter the name of the vaccine",
                        preferredStyle: .alert
                    )
                    inputAlert.addTextField { textField in
                        textField.placeholder = "Vaccine Name"
                    }
                    inputAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    inputAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        if let text = inputAlert.textFields?.first?.text, !text.isEmpty {
                            self.selectedVaccineName = text
                            self.vaccineNameButton.setTitle(text, for: .normal)
                            self.vaccineNameButton.setTitleColor(.label, for: .normal)
                        }
                    }))
                    self.present(inputAlert, animated: true, completion: nil)
                } else {
                    // Standard vaccine selected
                    self.selectedVaccineName = vaccine
                    self.vaccineNameButton.setTitle(vaccine, for: .normal)
                    self.vaccineNameButton.setTitleColor(.label, for: .normal)
                }
            }))
        }
        
        // Cancel
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }
        
        present(alert, animated: true)
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveVaccination(_ sender: UIBarButtonItem) {
        print("Save Button Clicked")
        
        guard let petId = petId else {
            print("Pet ID is missing!")
            return
        }
        
        // 1) Ensure the user selected a vaccine
        guard let vaccineName = selectedVaccineName, vaccineName != "Select" else {
            let alert = UIAlertController(
                title: "Vaccine Missing",
                message: "Please select or enter a vaccine name before saving.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }
        
        // 2) Format the date of vaccination and expiry
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        let dateOfVaccination = dateFormatter.string(from: dateOfVaccinePicker.date)
        
        var expiryDateString: String? = nil
        if expiresSwitch.isOn {
            expiryDateString = dateFormatter.string(from: expiryDatePicker.date)
        }
        
        // 3) Build the model
        let vaccination = VaccinationDetails(
            vaccineName: vaccineName,
            dateOfVaccination: dateOfVaccination,
            expires: expiresSwitch.isOn,
            expiryDate: expiryDateString,
            notifyUponExpiry: expiresSwitch.isOn ? notifyUponExpirySwitch.isOn : false,
            notes: notesTextView.text
        )
        
        activityIndicator.startAnimating()
        
       
        FirebaseManager.shared.saveVaccinationData(petId: petId, vaccination: vaccination) { error in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                        
                    if let error = error {
                        print("Failed to save vaccination: \(error.localizedDescription)")
                        let errorAlert = UIAlertController(
                            title: "Error",
                            message: "Failed to save vaccination: \(error.localizedDescription)",
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(errorAlert, animated: true)
                            } else {
                                print("Vaccination saved successfully!")
                            
                                let alertController = UIAlertController(
                                title: nil,
                                message: "Vaccination Data Added",
                                preferredStyle: .alert
                                )
                                self.present(alertController, animated: true, completion: nil)
                            
                            
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                alertController.dismiss(animated: true) {
                                    NotificationCenter.default.post(name:
                                    NSNotification.Name("VaccinationDataAdded"), object: nil)
                                    self.dismiss(animated: true, completion: nil)
                                }
                            }
                        }
                    }
                }
            }
        }

// MARK: - UITableViewDelegate
extension Add_Vaccination {
    
    // Hide Expiry Date (row 1) & Notify Switch (row 2) if expiresSwitch is OFF
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        
        if indexPath.section == 1 {
            // Hide row 1 (expiry date) & row 2 (notify upon expiry) if switch is off
            if (indexPath.row == 1 || indexPath.row == 2) {
                return expiresSwitch.isOn ? UITableView.automaticDimension : 0
            }
        }
        
        return UITableView.automaticDimension
    }
}
