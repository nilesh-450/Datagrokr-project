# CLI Grade Calculator
# Uses functions, loops, and dictionaries

def get_marks():
    """Take subject names and marks from user, store in a dictionary."""
    marks = {}
    try:
        n = int(input("Enter number of subjects: "))
    except ValueError:
        print("Please enter a valid number.")
        return marks

    for i in range(n):
        subject = input(f"Enter name of subject {i + 1}: ")
        while True:
            try:
                score = float(input(f"Enter marks for {subject} (out of 100): "))
                if 0 <= score <= 100:
                    break
                else:
                    print("Marks must be between 0 and 100.")
            except ValueError:
                print("Please enter a valid number.")
        marks[subject] = score

    return marks


def calculate_total_and_average(marks):
    """Calculate total and average marks from the dictionary."""
    total = sum(marks.values())
    average = total / len(marks) if marks else 0
    return total, average


def calculate_grade(average):
    """Return a letter grade based on average marks."""
    if average >= 90:
        return "A+"
    elif average >= 80:
        return "A"
    elif average >= 70:
        return "B"
    elif average >= 60:
        return "C"
    elif average >= 50:
        return "D"
    else:
        return "F"


def display_report(marks, total, average, grade):
    """Print a neat report of all subjects and results."""
    print("\n----- GRADE REPORT -----")
    for subject, score in marks.items():
        print(f"{subject:<15}: {score}")
    print("-------------------------")
    print(f"Total Marks   : {total}")
    print(f"Average       : {average:.2f}")
    print(f"Grade         : {grade}")
    print("-------------------------")


def main():
    print("=== CLI Grade Calculator ===")
    marks = get_marks()

    if not marks:
        print("No data entered. Exiting.")
        return

    total, average = calculate_total_and_average(marks)
    grade = calculate_grade(average)
    display_report(marks, total, average, grade)


if __name__ == "__main__":
    main()