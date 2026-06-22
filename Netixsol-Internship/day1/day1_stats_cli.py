def find_mean(numbers: list[int]) -> float:
    total = sum(numbers)
    mean = total / len(numbers)
    return mean

def find_median(numbers: list[int]) -> int | float:
    numbers.sort()
    if len(numbers) % 2 != 0:
        index = len(numbers) // 2
        return numbers[index]
    else:
        index1 = (len(numbers) // 2)
        index2 = len(numbers) // 2 + 1
        return (index1 + index2) / 2

def find_mode(numbers: list[int]) -> int:
    count = [0] * len(numbers)
    for i in range(len(numbers)):
        for j in range(len(numbers)):
            if numbers[i] == numbers[j]:
                count[i] += 1
            else:
                pass
    biggest = max(count)
    index = count.index(biggest)
    return numbers[index]
    

def find_min(numbers: list[int]) -> int:
    min = numbers[0]
    for i in numbers:
        if i < min:
            min = i
    return min

def find_max(numbers: list[int]) -> int:
    max = numbers[0]
    for i in numbers:
        if i > max:
            max = i
    return max


def main():
    nums = input("Enter a comma separated list of numbers: ").split(",")
    for n in range(len(nums)):
        nums[n] = int(nums[n])
    print(f"Mean is: {find_mean(nums)}")
    print(f"Median is: {find_median(nums)}")
    print(f"Mode is: {find_mode(nums)}")
    print(f"Min is: {find_min(nums)}")
    print(f"Max is: {find_max(nums)}")

main()