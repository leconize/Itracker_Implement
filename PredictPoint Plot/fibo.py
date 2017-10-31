def fibo():
    a,b = 1, 1
    for i in range(int(input())):
        a, b = b, a+b
    print(a,b)

mem = {1: 1, 2: 1}
def refibo(i):
    if i not in mem:
        mem[i] = refibo(i-1) + refibo(i-2)
    return mem[i]
print(refibo(35))

def normalfibo(i):
    if i <= 2:
        return 1
    else:
        return normalfibo(i-1) + normalfibo(i-2)

print(normalfibo(35))
