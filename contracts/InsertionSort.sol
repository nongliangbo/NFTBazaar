pragma solidity ^0.8.24;

contract InsertionSort {

    uint256[] array;

    function insertionSort(uint[] memory arr) public  returns (uint[] memory) {
        //编写一个快速排序
        for (uint i = 1; i < arr.length; i++) {
            uint j = i;
            while (j > 0 && arr[j - 1] > arr[j]) {
                uint temp = arr[j];
                arr[j] = arr[j - 1];
                arr[j - 1] = temp;
                j--;
            }
        }
        array = arr;
        return arr;

    }

}